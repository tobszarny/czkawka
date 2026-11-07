use log::trace;
use slint::{ComponentHandle, Model, ModelRc, VecModel};

use crate::connect_row_selection::checker::change_number_of_enabled_items;
use crate::connect_row_selection::selection::{SELECTED_ROWS_LIMIT, SelectionData, get_write_selection_lock};
use crate::{Callabler, GuiState, MainWindow, SingleMainListModel};

#[derive(Debug)]
struct GroupRange {
    start_idx: usize,
    item_count: usize,
}

impl GroupRange {
    fn end_idx(&self) -> usize {
        self.start_idx + self.item_count
    }

    fn contains(&self, idx: usize) -> bool {
        (self.start_idx..self.end_idx()).contains(&idx)
    }
}

fn find_group_range(model: &ModelRc<SingleMainListModel>, header_idx: usize) -> GroupRange {
    let header = model
        .row_data(header_idx)
        .unwrap_or_else(|| panic!("row_select_group: index {header_idx} out of bounds (row_count={})", model.row_count()));
    assert!(
        header.header_row,
        "row_select_group: row {header_idx} is not a header row - model is out of sync with the UI"
    );

    let item_count = model.iter().enumerate().skip(header_idx + 1).take_while(|(_, row)| !row.header_row).count();

    GroupRange {
        start_idx: header_idx + 1,
        item_count,
    }
}

// Toggles the whole group: all items checked -> uncheck and unfocus all, otherwise check and focus all.
// Returns the model to swap in (only when a full replacement was cheaper) and the checked-items delta.
fn select_group(selection: &mut SelectionData, model: &ModelRc<SingleMainListModel>, range: &GroupRange) -> (Option<ModelRc<SingleMainListModel>>, i64) {
    if range.item_count == 0 {
        return (None, 0);
    }

    let group_items: Vec<_> = model.iter().enumerate().skip(range.start_idx).take(range.item_count).collect();
    let checked_before = group_items.iter().filter(|(_, row)| row.checked).count();
    let should_select = checked_before < range.item_count;
    let checked_after = if should_select { range.item_count } else { 0 };
    let checked_delta = checked_after as i64 - checked_before as i64;

    if range.item_count > SELECTED_ROWS_LIMIT || selection.exceeded_limit {
        trace!("[SLOW][REPLACE_MODEL] toggling {} group items", range.item_count);
        let new_rows: Vec<_> = model
            .iter()
            .enumerate()
            .map(|(idx, mut row)| {
                if range.contains(idx) {
                    row.checked = should_select;
                    row.focused_row = should_select;
                }
                row
            })
            .collect();

        selection.exceeded_limit = true;
        selection.selected_rows.clear();
        selection.number_of_selected_rows = new_rows.iter().filter(|row| row.focused_row).count();

        (Some(ModelRc::new(VecModel::from(new_rows))), checked_delta)
    } else {
        trace!("[FAST][ONE_BY_ONE] toggling {} group items", range.item_count);
        for (idx, mut row) in group_items {
            row.checked = should_select;
            row.focused_row = should_select;
            model.set_row_data(idx, row);
        }

        // selected_rows mirrors focused rows; only the toggled range changed membership
        selection.selected_rows.retain(|&idx| !range.contains(idx));
        if should_select {
            selection.selected_rows.extend(range.start_idx..range.end_idx());
            selection.selected_rows.sort_unstable();
        }
        selection.number_of_selected_rows = selection.selected_rows.len();

        (None, checked_delta)
    }
}

pub(crate) fn connect_select_group_items(app: &MainWindow) {
    let a = app.as_weak();
    app.global::<Callabler>().on_row_select_group(move |header_idx| {
        trace!("Double-clicked group header at index {header_idx}");
        let app = a.upgrade().expect("Failed to upgrade app :(");
        let active_tab = app.global::<GuiState>().get_active_tab();

        let (new_model, checked_delta) = {
            let mut lock = get_write_selection_lock();
            let selection = lock.get_mut(&active_tab).expect("Failed to get selection data");
            let model = active_tab.get_tool_model(&app);

            let range = find_group_range(&model, header_idx as usize);
            select_group(selection, &model, &range)
        };

        if let Some(new_model) = new_model {
            active_tab.set_tool_model(&app, new_model);
        }
        if checked_delta != 0 {
            change_number_of_enabled_items(&app, active_tab, checked_delta);
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::common::create_model_from_model_vec;
    use crate::test_common::get_model_vec;

    fn model_with_two_groups() -> ModelRc<SingleMainListModel> {
        let mut model = get_model_vec(6);
        model[0].header_row = true;
        model[3].header_row = true;
        create_model_from_model_vec(&model)
    }

    #[test]
    fn find_group_range_returns_items_until_next_header() {
        let model = model_with_two_groups();

        let first = find_group_range(&model, 0);
        assert_eq!(first.start_idx, 1);
        assert_eq!(first.item_count, 2);

        let second = find_group_range(&model, 3);
        assert_eq!(second.start_idx, 4);
        assert_eq!(second.item_count, 2);
    }

    #[test]
    fn find_group_range_covers_trailing_group_without_next_header() {
        let model = model_with_two_groups();

        let range = find_group_range(&model, 3);
        assert_eq!(range.end_idx(), model.row_count());
    }

    #[test]
    fn select_group_checks_and_focuses_all_items() {
        let model = model_with_two_groups();

        let mut selection = SelectionData::default();
        let (new_model, checked_delta) = select_group(&mut selection, &model, &find_group_range(&model, 0));

        assert!(new_model.is_none());
        assert_eq!(checked_delta, 2);
        assert!(!model.row_data(0).unwrap().focused_row); // header stays untouched
        assert!(model.row_data(1).unwrap().checked);
        assert!(model.row_data(1).unwrap().focused_row);
        assert!(model.row_data(2).unwrap().checked);
        assert!(model.row_data(2).unwrap().focused_row);
        assert!(!model.row_data(4).unwrap().checked); // other group untouched
        assert_eq!(selection.selected_rows, vec![1, 2]);
        assert_eq!(selection.number_of_selected_rows, 2);
    }

    #[test]
    fn select_group_unchecks_fully_checked_group() {
        let mut rows = get_model_vec(6);
        rows[0].header_row = true;
        rows[3].header_row = true;
        rows[1].checked = true;
        rows[2].checked = true;
        let model = create_model_from_model_vec(&rows);

        let mut selection = SelectionData {
            number_of_selected_rows: 0,
            selected_rows: Vec::new(),
            exceeded_limit: false,
        };
        let (new_model, checked_delta) = select_group(&mut selection, &model, &find_group_range(&model, 0));

        assert!(new_model.is_none());
        assert_eq!(checked_delta, -2);
        assert!(!model.row_data(1).unwrap().checked);
        assert!(!model.row_data(1).unwrap().focused_row);
        assert!(!model.row_data(2).unwrap().checked);
        assert!(selection.selected_rows.is_empty());
    }

    #[test]
    fn select_group_keeps_selection_of_other_groups() {
        let mut rows = get_model_vec(6);
        rows[0].header_row = true;
        rows[3].header_row = true;
        rows[4].focused_row = true;
        let model = create_model_from_model_vec(&rows);

        let mut selection = SelectionData {
            number_of_selected_rows: 1,
            selected_rows: vec![4],
            exceeded_limit: false,
        };
        let (_, checked_delta) = select_group(&mut selection, &model, &find_group_range(&model, 0));

        assert_eq!(checked_delta, 2);
        assert!(model.row_data(4).unwrap().focused_row); // still focused
        assert!(!model.row_data(4).unwrap().checked); // still untouched by the toggle
        assert_eq!(selection.selected_rows, vec![1, 2, 4]);
        assert_eq!(selection.number_of_selected_rows, 3);
    }

    #[test]
    fn select_group_with_empty_group_is_noop() {
        let mut rows = get_model_vec(2);
        rows[0].header_row = true;
        rows[1].header_row = true;
        let model = create_model_from_model_vec(&rows);

        let mut selection = SelectionData::default();
        let (new_model, checked_delta) = select_group(&mut selection, &model, &GroupRange { start_idx: 1, item_count: 0 });

        assert!(new_model.is_none());
        assert_eq!(checked_delta, 0);
        assert!(selection.selected_rows.is_empty());
    }
}
