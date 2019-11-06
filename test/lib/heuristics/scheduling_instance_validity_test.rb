# Copyright © Mapotempo, 2019
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require './test/test_helper'

class InstanceValidityTest < Minitest::Test
  if !ENV['SKIP_SCHEDULING']
    def test_reject_if_no_heuristic_neither_first_sol_strategy
      problem = VRP.scheduling
      problem[:configuration][:preprocessing][:first_solution_strategy] = []
      problem[:configuration][:resolution][:solver_parameter] = -1

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_solver_if_not_periodic
    end

    def test_reject_if_partial_assignement
      problem = VRP.scheduling
      problem[:configuration][:resolution][:allow_partial_assignment] = false
      problem[:configuration][:preprocessing][:first_solution_strategy] = nil

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include?(:assert_no_allow_partial_if_no_heuristic)
    end

    def test_reject_if_same_point_day
      problem = VRP.scheduling
      problem[:configuration][:resolution][:same_point_day] = true
      problem[:configuration][:preprocessing][:first_solution_strategy] = nil

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include?(:assert_no_same_point_day_if_no_heuristic)
    end

    def test_do_not_solve_if_range_index_and_month_duration
      problem = VRP.scheduling
      problem[:relations] = [{
        type: 'vehicle_group_duration_on_months',
        linked_vehicle_ids: %w[vehicle_1 vehicle_2],
        lapse: 5,
        periodicity: 1
      }]

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include?(:assert_range_date_if_month_duration)
    end

    def test_reject_if_relation
      problem = VRP.scheduling
      problem[:relations] = [{
        type: 'vehicle_group_duration_on_weeks',
        lapse: '2',
        linked_vehicle_ids: ['vehicle_0']
      }]

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_no_relation_with_scheduling_heuristic
    end

    def test_reject_if_vehicle_shift_preference
      problem = VRP.scheduling
      problem[:vehicles].first[:shift_preference] = 'force_start'

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_wrong_vehicle_shift_preference_with_heuristic
    end

    def test_reject_if_vehicle_overall_duration
      problem = VRP.scheduling
      problem[:vehicles].first[:overall_duration] = 10

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_no_vehicle_overall_duration_if_heuristic
    end

    def test_reject_if_vehicle_distance
      problem = VRP.scheduling
      problem[:vehicles].first[:distance] = 10

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_no_vehicle_distance_if_heuristic
    end

    def test_reject_if_vehicle_skills
      problem = VRP.scheduling
      problem[:vehicles].first[:skills] = ['skill']
      problem[:services].first[:skills] = ['skill']

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_no_skills_if_heuristic
    end

    def test_reject_if_vehicle_free_approach_return
      problem = VRP.scheduling
      problem[:vehicles].first[:free_approach] = true

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_no_vehicle_free_approach_or_return_if_heuristic
    end

    def test_reject_if_service_exclusion_cost
      problem = VRP.scheduling
      problem[:services].first[:exclusion_cost] = 1

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_no_service_exclusion_cost_if_heuristic
    end

    def test_reject_if_vehicle_limit
      problem = VRP.scheduling
      problem[:configuration][:resolution][:vehicle_limit] = 1

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).empty?

      problem[:vehicles] *= 3

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_no_vehicle_limit_if_heuristic
    end

    def test_reject_if_no_vehicle_tw_but_heuristic
      problem = VRP.scheduling
      problem[:vehicles].first[:timewindow] = nil

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_vehicle_tw_if_schedule
    end

    def test_reject_if_periodic_heuristic_without_schedule
      problem = VRP.scheduling
      problem[:configuration][:schedule] = nil

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_if_periodic_heuristic_then_schedule
    end

    def test_no_solution_evaluation
      problem = VRP.scheduling
      problem[:configuration][:resolution][:evaluate_only] = true

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_no_scheduling_if_evaluation
    end

    def test_no_activities
      problem = VRP.scheduling
      problem[:services].first[:activity] = nil
      problem[:services].first[:activities] = [{
        point_id: 'point_1'
      }, {
        point_id: 'point_2'
      }]

      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_only_one_activity_with_scheduling_heuristic
    end

    def test_assert_route_day_if_periodic
      problem = VRP.scheduling
      problem[:routes] = [{
        vehicle_id: 'vehicle_0',
        mission_ids: ['service_1', 'service_3']
      }]
      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_route_day_if_periodic

      problem[:routes] = [{
        vehicle_id: 'vehicle_0',
        day: 0,
        mission_ids: ['service_1', 'service_3']
      }]
      assert !(OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_route_day_if_periodic)
    end

    def test_service_with_visit_index_in_route_if_periodic
      problem = VRP.scheduling
      problem[:routes] = [{
        vehicle_id: 'vehicle_0',
        day: 0,
        mission_ids: ['service_1', 'service_3']
      }]
      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_service_with_visit_index_in_route_if_periodic

      problem[:routes] = [{
        vehicle_id: 'vehicle_0',
        day: 0,
        mission_ids: ['service_1_1_1', 'service_3_1']
      }]
      assert OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_service_with_visit_index_in_route_if_periodic

      problem[:routes] = [{
        vehicle_id: 'vehicle_0',
        day: 0,
        mission_ids: ['service_1_1_1', 'service_3_1_2']
      }]
      assert !(OptimizerWrapper.config[:services][:ortools].inapplicable_solve?(FCT.create(problem)).include? :assert_service_with_visit_index_in_route_if_periodic)
    end
  end
end
