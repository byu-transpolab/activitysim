# ActivitySim
# See full license in LICENSE.txt.

import os
import logging

import pandas as pd

from activitysim.core.simulate import read_model_spec
from activitysim.core.interaction_simulate import interaction_simulate

from activitysim.core import simulate as asim
from activitysim.core import tracing
from activitysim.core import pipeline
from activitysim.core import config
from activitysim.core import inject
from activitysim.core import timetable as tt
from .util.vectorize_tour_scheduling import vectorize_subtour_scheduling
from .util import expressions

from activitysim.core.util import assign_in_place

logger = logging.getLogger(__name__)

DUMP = False


@inject.injectable()
def tour_scheduling_atwork_spec(configs_dir):
    return asim.read_model_spec(configs_dir, 'tour_scheduling_atwork.csv')


@inject.injectable()
def atwork_subtour_scheduling_settings(configs_dir):
    return config.read_model_settings(configs_dir, 'atwork_subtour_scheduling.yaml')


@inject.step()
def atwork_subtour_scheduling(
        tours,
        persons_merged,
        tdd_alts,
        tour_scheduling_atwork_spec,
        atwork_subtour_scheduling_settings,
        chunk_size,
        trace_hh_id):
    """
    This model predicts the departure time and duration of each activity for at work subtours tours
    """

    trace_label = 'tour_scheduling_subtour'
    constants = config.get_model_constants(atwork_subtour_scheduling_settings)

    persons_merged = persons_merged.to_frame()

    tours = tours.to_frame()
    subtours = tours[tours.tour_category == 'atwork']

    # - if no atwork subtours
    if subtours.shape[0] == 0:
        tracing.no_results(trace_label)
        return

    logger.info("Running %s with %d tours" % (trace_label, len(subtours)))

    # parent_tours table with columns ['tour_id', 'tdd'] index = tour_id
    parent_tour_ids = subtours.parent_tour_id.astype(int).unique()
    parent_tours = pd.DataFrame({'tour_id': parent_tour_ids}, index=parent_tour_ids)
    parent_tours = parent_tours.merge(tours[['tdd']], left_index=True, right_index=True)

    """
    parent_tours
               tour_id   tdd
    20973389  20973389    26
    44612864  44612864     3
    48954854  48954854     7
    """

    tdd_choices = vectorize_subtour_scheduling(
        parent_tours,
        subtours,
        persons_merged,
        tdd_alts, tour_scheduling_atwork_spec,
        constants=constants,
        chunk_size=chunk_size,
        trace_label=trace_label)

    assign_in_place(tours, tdd_choices)
    pipeline.replace_table("tours", tours)

    tracing.dump_df(DUMP,
                    tt.tour_map(parent_tours, subtours, tdd_alts, persons_id_col='parent_tour_id'),
                    trace_label, 'tour_map')

    if trace_hh_id:
        tracing.trace_df(tours[tours.tour_category == 'atwork'],
                         label="atwork_subtour_scheduling",
                         slicer='person_id',
                         index_label='tour_id',
                         columns=None)
