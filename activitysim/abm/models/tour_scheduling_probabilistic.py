# ActivitySim
# See full license in LICENSE.txt

import logging

import numpy as np
import pandas as pd

from activitysim.core import logit
from activitysim.core import config
from activitysim.core import inject
from activitysim.core import tracing
from activitysim.core import chunk
from activitysim.core import pipeline

from activitysim.core.util import reindex

from .util import probabilistic_scheduling as ps


logger = logging.getLogger(__name__)


def run_tour_scheduling_probabilistic(
        tours_df, scheduling_probs, probs_join_cols, depart_alt_base, chunk_size,
        trace_label, trace_hh_id):
    row_size = chunk_size and ps.calc_row_size(
            tours_df, scheduling_probs, probs_join_cols, trace_label, 'tour')

    result_list = []
    for i, chooser_chunk, chunk_trace_label \
        in chunk.adaptive_chunked_choosers(tours_df, chunk_size, row_size, trace_label):
            choices = ps.make_scheduling_choices(
                chooser_chunk, 'departure', scheduling_probs, probs_join_cols, depart_alt_base,
                first_trip_in_leg=False, report_failed_trips=True,
                trace_label=chunk_trace_label, trace_hh_id=trace_hh_id,
                trace_choice_col_name='depart_return', clip_earliest_latest=False)
            result_list.append(choices)

    choices = pd.concat(result_list)
    return choices


@inject.step()
def tour_scheduling_probabilistic(
        tours,
        chunk_size,
        trace_hh_id):
    
    trace_label = "tour_scheduling_probabilistic"
    model_settings = config.read_model_settings('tour_scheduling_probabilistic.yaml')
    depart_alt_base = model_settings.get('depart_alt_base', 0)
    scheduling_probs_filepath = config.config_file_path(model_settings['SCHEDULING_PROBS'])
    scheduling_probs = pd.read_csv(scheduling_probs_filepath)
    probs_join_cols = model_settings['PROBS_JOIN_COLS']
    tours_df = tours.to_frame()

    choices = run_tour_scheduling_probabilistic(
        tours_df, scheduling_probs, probs_join_cols, depart_alt_base, chunk_size,
        trace_label, trace_hh_id)

    # convert alt index choices to depart/return times
    probs_cols = pd.Series([c for c in scheduling_probs.columns if c not in probs_join_cols])
    dep_ret_choices = probs_cols.loc[choices]
    dep_ret_choices.index = choices.index
    choices.update(dep_ret_choices)
    departures = choices.str.split('_').str[0].astype(int)
    returns = choices.str.split('_').str[1].astype(int)

    # these column names are required for downstream models (e.g. tour mode choice)
    # normally generated by time_windows.py and used as alts for vectorize_tour_scheduling
    tours_df['start'] = departures
    tours_df['end'] = returns
    tours_df['duration'] = tours_df['end'] - tours_df['start']

    assert not tours_df['start'].isnull().any()
    assert not tours_df['end'].isnull().any()
    assert not tours_df['duration'].isnull().any()

    pipeline.replace_table("tours", tours_df)

