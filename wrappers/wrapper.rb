# Copyright © Mapotempo, 2016
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
module Wrappers
  class Wrapper
    def initialize(cache, hash = {})
      @cache = cache
      @tmp_dir = hash[:tmp_dir] || Dir.tmpdir
      @threads = hash[:threads] || 1
    end

    def solver_constraints
      [
       :assert_no_pickup_timewindows_after_delivery_timewindows,
      ]
    end

    def inapplicable_solve?(vrp)
      solver_constraints.select{ |constraint|
        !self.send(constraint, vrp)
      }
    end

    def assert_points_same_definition(vrp)
      (vrp.points.all?(&:location) || vrp.points.none?(&:location)) && (vrp.points.all?(&:matrix_index) || vrp.points.none?(&:matrix_index))
    end

    def assert_units_only_one(vrp)
      vrp.units.size <= 1
    end

    def assert_vehicles_only_one(vrp)
      vrp.vehicles.size == 1 && !vrp.scheduling?
    end

    def assert_vehicles_at_least_one(vrp)
      vrp.vehicles.size >= 1 && (vrp.vehicles.none?(&:duration) || vrp.vehicles.any?{ |vehicle| vehicle.duration && vehicle.duration > 0 })
    end

    def assert_vehicles_start(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        vehicle.start_point.nil?
      }
    end

    def assert_vehicles_start_or_end(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        vehicle.start_point.nil? && vehicle.end_point.nil?
      }
    end

    def assert_vehicles_no_timewindow(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        !vehicle.timewindow.nil?
      }
    end

    def assert_vehicles_no_rests(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        !vehicle.rests.empty?
      }
    end

    def assert_services_no_capacities(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        !vehicle.capacities.empty?
      }
    end

    def assert_vehicles_capacities_only_one(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        vehicle.capacities.size > 1
      }
    end

    def assert_vehicles_no_capacity_initial(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        vehicle.capacities.find{ |c| c.initial && c.initial > 0 }
      }
    end

    def assert_vehicles_no_alternative_skills(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        !vehicle.skills || vehicle.skills.size > 1
      }
    end

    def assert_no_shipments(vrp)
      vrp.shipments.empty?
    end

    def assert_no_shipments_with_multiple_timewindows(vrp)
      vrp.shipments.empty? || vrp.shipments.none? { |shipment|
        shipment.pickup.timewindows.size > 1 || shipment.delivery.timewindows.size > 1
      }
    end

    def assert_no_pickup_timewindows_after_delivery_timewindows(vrp)
      vrp.shipments.empty? || vrp.shipments.none? { |shipment|
        first_open = shipment.pickup.timewindows.min_by(&:start)
        last_close = shipment.delivery.timewindows.max_by(&:end)
        first_open && last_close && (first_open.start.to_i || 0) + 86400 * (first_open.day_index || 0) >
          (last_close.end.to_i || 86399 ) + 86400 * (last_close.day_index || 0)
      }
    end

    def assert_services_no_skills(vrp)
      vrp.services.empty? || vrp.services.none?{ |service|
        !service.skills.empty?
      }
    end

    def assert_services_no_timewindows(vrp)
      vrp.services.empty? || vrp.services.none?{ |service|
        !service.activity.timewindows.empty?
      }
    end

    def assert_services_no_multiple_timewindows(vrp)
      vrp.services.empty? || vrp.services.none?{ |service|
        service.activity.timewindows.size > 1
      }
    end

    def assert_services_at_most_two_timewindows(vrp)
      vrp.services.empty? || vrp.services.none?{ |service|
        service.activity.timewindows.size > 2
      }
    end

    def assert_services_no_priority(vrp)
      vrp.services.empty? || vrp.services.all?{ |service|
        service.priority == 4
      }
    end

    def assert_vehicles_objective(vrp)
      vrp.vehicles.all?{ |vehicle|
        vehicle.cost_time_multiplier && vehicle.cost_time_multiplier > 0 ||
        vehicle.cost_distance_multiplier && vehicle.cost_distance_multiplier > 0 ||
        vehicle.cost_waiting_time_multiplier && vehicle.cost_waiting_time_multiplier > 0 ||
        vehicle.cost_value_multiplier && vehicle.cost_value_multiplier > 0
      }
    end

    def assert_vehicles_no_late_multiplier(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        vehicle.cost_late_multiplier && vehicle.cost_late_multiplier > 0
      }
    end

    def assert_vehicles_no_overload_multiplier(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        vehicle.capacities.find{ |capacity|
          capacity.overload_multiplier && capacity.overload_multiplier > 0
        }
      }
    end

    def assert_vehicles_no_force_start(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?(&:force_start)
    end

    def assert_vehicles_no_duration_limit(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?(&:duration)
    end

    def assert_vehicles_no_zero_duration(vrp)
      vrp.vehicles.empty? || vrp.vehicles.none?{ |vehicle|
        vehicle.duration && vehicle.duration == 0
      }
    end

    def assert_services_no_late_multiplier(vrp)
      vrp.services.empty? || vrp.services.none?{ |service|
        service.activity.late_multiplier && service.activity.late_multiplier > 0
      }
    end

    def assert_shipments_no_late_multiplier(vrp)
      vrp.shipments.empty? || vrp.shipments.none?{ |shipment|
        shipment.pickup.late_multiplier && shipment.pickup.late_multiplier > 0 || shipment.delivery.late_multiplier && shipment.delivery.late_multiplier > 0
      }
    end

    def assert_services_quantities_only_one(vrp)
      vrp.services.empty? || vrp.services.none?{ |service|
        service.quantities.size > 1
      }
    end

    def assert_matrices_only_one(vrp)
      vrp.vehicles.collect{ |vehicle|
        vehicle.matrix_id || [vehicle.router_mode.to_sym, vehicle.router_dimension, vehicle.speed_multiplier]
      }.uniq.size == 1
    end

    def assert_square_matrix(vrp)
      dimensions = vrp.vehicles.collect(&:dimensions).flatten.uniq
      vrp.matrices.all?{ |matrix|
        dimensions.all?{ |dimension|
          matrix[dimension].nil? || matrix[dimension].all?{ |line| matrix[dimension].size == line.size }
        }
      }
    end

    def assert_correctness_provided_matrix_indices(vrp)
      dimensions = vrp.vehicles.collect(&:dimensions).flatten.uniq
      max_matrix_index = vrp.points.collect(&:matrix_index).max || 0
      vrp.matrices.all?{ |matrix|
        dimensions.all?{ |dimension|
          matrix[dimension].nil? || matrix[dimension].size > max_matrix_index && matrix[dimension].all?{ |line| line.size > max_matrix_index }
        }
      }
    end

    def assert_correctness_matrices_vehicles_and_points_definition(vrp)
      # Either there is no matrix and all points are with a location
      # or all points and vehicles have matrix_index and matrix_id, respectively
      (vrp.matrices.count{ |matrix| matrix[:time] || matrix[:distance] }.zero? && vrp.points.all?(&:location)) ||
        (vrp.points.all?(&:matrix_index) && vrp.vehicles.all?(&:matrix_id))
    end

    def assert_one_sticky_at_most(vrp)
      (vrp.services.empty? || vrp.services.none?{ |service|
        service.sticky_vehicles.size > 1
      }) && (vrp.shipments.empty? || vrp.shipments.none?{ |shipment|
        shipment.sticky_vehicles.size > 1
      })
    end

    def assert_one_vehicle_only_or_no_sticky_vehicle(vrp)
      vrp.vehicles.size <= 1 ||
        (vrp.services.empty? || vrp.services.all?{ |service|
          service.sticky_vehicles.empty?
        }) && (vrp.shipments.empty? || vrp.shipments.all?{ |shipment|
          shipment.sticky_vehicles.empty?
        })
    end

    def assert_no_relations(vrp)
      vrp.relations.empty? || vrp.relations.all?{ |relation| relation.linked_ids.empty? && relation.linked_vehicle_ids.empty? }
    end

    def assert_no_zones(vrp)
      vrp.zones.empty?
    end

    def assert_zones_only_size_one_alternative(vrp)
      vrp.zones.empty? || vrp.zones.all?{ |zone| zone.allocations.none?{ |alternative| alternative.size > 1 }}
    end

    def assert_no_value_matrix(vrp)
      vrp.matrices.none?(&:value)
    end

    def assert_no_routes(vrp)
      vrp.routes.empty? || vrp.routes.all?{ |route| route.mission_ids.empty? }
    end

    def assert_no_subtours(vrp)
      vrp.subtours.empty?
    end

    def assert_only_empty_or_fill_quantities(vrp)
      problem_units = vrp.units.collect{ |unit|
        {
          unit_id: unit.id,
          fill: false,
          empty: false
        }
      }

      vrp.services.each{ |service|
        service.quantities.each{ |quantity|
          unit_status = problem_units.find{ |unit| unit[:unit_id] == quantity.unit_id }
          unit_status[:fill] ||= quantity.fill
          unit_status[:empty] ||= quantity.empty
          return false if unit_status[:fill] && unit_status[:empty]
        }
      }
      true
    end

    def assert_at_least_one_mission(vrp)
      !vrp.services.empty? || !vrp.shipments.empty?
    end

    def assert_end_optimization(vrp)
      vrp.resolution_duration || vrp.resolution_iterations_without_improvment
    end

    def assert_vehicles_no_end_time_or_late_multiplier(vrp)
      vrp.vehicles.empty? || vrp.vehicles.all?{ |vehicle|
        !vehicle.timewindow || vehicle.cost_late_multiplier && vehicle.cost_late_multiplier > 0
      }
    end

    def assert_no_distance_limitation(vrp)
      vrp[:vehicles].none?{ |vehicle| vehicle[:distance] }
    end

    def assert_range_date_if_month_duration(vrp)
      !(vrp[:relations] && vrp[:relations].any?{ |relation| relation[:type] == 'vehicle_group_duration_on_months' }) || vrp.schedule_range_date
    end

    def assert_vehicle_tw_if_schedule(vrp)
      vrp.preprocessing_first_solution_strategy.to_a.first != 'periodic' ||
      vrp[:vehicles].all?{ |vehicle|
        vehicle[:timewindow] && (vehicle[:timewindow][:start] || vehicle[:timewindow][:end]) ||
        vehicle[:sequence_timewindows] && vehicle[:sequence_timewindows].any?{ |tw| (tw[:start] || tw[:end]) }
      }
    end

    def assert_if_sequence_tw_then_schedule(vrp)
      vrp.vehicles.find{ |vehicle| vehicle[:sequence_timewindows] }.nil? || vrp.scheduling?
    end

    def assert_if_periodic_heuristic_then_schedule(vrp)
      vrp.preprocessing_first_solution_strategy.to_a.first != 'periodic' || vrp.scheduling?
    end

    def assert_first_solution_strategy_is_possible(vrp)
      vrp.preprocessing_first_solution_strategy.nil? || !vrp.resolution_evaluate_only && vrp.resolution_several_solutions.nil? &&
      !vrp.resolution_batch_heuristic && (!vrp.resolution_solver_parameter || vrp.resolution_solver_parameter == -1)
    end

    def assert_first_solution_strategy_is_valid(vrp)
      vrp.preprocessing_first_solution_strategy.nil? ||
        (vrp.preprocessing_first_solution_strategy[0] != 'self_selection' && vrp.preprocessing_first_solution_strategy[0] != 'periodic' || vrp.preprocessing_first_solution_strategy.size == 1) &&
          vrp.preprocessing_first_solution_strategy.all?{ |strategy| strategy == 'self_selection' || strategy == 'periodic' || OptimizerWrapper::HEURISTICS.include?(strategy) }
    end

    def assert_no_planning_heuristic(vrp)
      vrp.preprocessing_first_solution_strategy.to_a.first != 'periodic'
    end

    def assert_only_force_centroids_if_kmeans_method(vrp)
      vrp.preprocessing_kmeans_centroids.nil? || vrp.preprocessing_partition_method == 'balanced_kmeans'
    end

    def assert_no_evaluation(vrp)
      !vrp.resolution_evaluate_only
    end

    def assert_no_shipments_if_evaluation(vrp)
      (!vrp.shipments || vrp.shipments.empty?) || !vrp.resolution_evaluate_only
    end

    def assert_no_scheduling_if_evaluation(vrp)
      !vrp.scheduling? || !vrp.resolution_evaluate_only
    end

    def assert_route_if_evaluation(vrp)
      !vrp.resolution_evaluate_only || vrp[:routes] && !vrp[:routes].empty?
    end

    def assert_wrong_vehicle_shift_preference_with_heuristic(vrp)
      (vrp.vehicles.collect{ |vehicle| vehicle[:shift_preference] }.uniq - [:minimize_span] - ['minimize_span']).size == 0 || vrp.preprocessing_first_solution_strategy.to_a.first != 'periodic'
    end

    def assert_no_vehicle_overall_duration_if_heuristic(vrp)
      vrp.vehicles.none?{ |vehicle| vehicle[:overall_duration] } || vrp.preprocessing_first_solution_strategy.to_a.first != 'periodic'
    end

    def assert_no_vehicle_distance_if_heuristic(vrp)
      vrp.vehicles.none?{ |vehicle| vehicle[:distance] } || vrp.preprocessing_first_solution_strategy.to_a.first != 'periodic'
    end

    def assert_possible_to_get_distances_if_maximum_ride_distance(vrp)
      !vrp.vehicles.any?{ |vehicle| vehicle[:maximum_ride_distance] } || (vrp.points.all?{ |point| point[:location] && point[:location][:lat] } || vrp.matrices.all?{ |matrix| matrix[:distance] && !matrix[:distance].empty? })
    end

    def assert_no_skills_if_heuristic(vrp)
      vrp.services.none?{ |service| !service[:skills].empty? } || vrp.vehicles.none?{ |vehicle| !vehicle[:skills].empty? } || vrp.preprocessing_first_solution_strategy.to_a.first != 'periodic' || !vrp.preprocessing_partitions.empty?
    end

    def assert_no_vehicle_free_approach_or_return_if_heuristic(vrp)
      vrp.vehicles.none?{ |vehicle| vehicle[:free_approach] || vehicle[:free_return] } || vrp.preprocessing_first_solution_strategy.to_a.first != 'periodic'
    end

    def assert_no_service_exclusion_cost_if_heuristic(vrp)
      vrp.services.collect{ |service| service[:exclusion_cost] }.compact.empty? || vrp.preprocessing_first_solution_strategy.to_a.first != 'periodic'
    end

    def assert_no_vehicle_limit_if_heuristic(vrp)
      vrp.resolution_vehicle_limit.nil? || vrp.resolution_vehicle_limit >= vrp.vehicles.size || vrp.preprocessing_first_solution_strategy.to_a.first != 'periodic'
    end

    def assert_no_same_point_day_if_no_heuristic(vrp)
      !vrp.resolution_same_point_day || vrp.preprocessing_first_solution_strategy.to_a.first == 'periodic'
    end

    def assert_no_allow_partial_if_no_heuristic(vrp)
      vrp.resolution_allow_partial_assignment || vrp.preprocessing_first_solution_strategy.to_a.first == 'periodic'
    end

    def assert_no_first_solution_strategy(vrp)
      vrp.preprocessing_first_solution_strategy.nil? || vrp.preprocessing_first_solution_strategy.empty? || vrp.preprocessing_first_solution_strategy == ['self_selection']
    end

    def assert_solver(vrp)
      vrp.resolution_solver
    end

    def assert_solver_if_not_periodic(vrp)
      (vrp.resolution_solver && vrp.resolution_solver_parameter != -1) || vrp.preprocessing_first_solution_strategy && (vrp.preprocessing_first_solution_strategy.first == 'periodic')
    end

    def assert_clustering_compatible_with_scheduling_heuristic(vrp)
      (!vrp.preprocessing_first_solution_strategy || !vrp.preprocessing_first_solution_strategy.include?('periodic')) || !vrp.preprocessing_cluster_threshold && !vrp.preprocessing_max_split_size
    end

    def assert_lat_lon_for_partition(vrp)
      vrp.preprocessing_partition_method.nil? || vrp.points.all?{ |pt| pt[:location] && pt[:location][:lat] && pt[:location][:lon] }
    end

    def assert_work_day_partitions_only_schedule(vrp)
      vrp.preprocessing_partitions.empty? || vrp.preprocessing_partitions.size < 2 ||
      vrp.scheduling? &&
      (vrp.services.none?{ |service| service[:minimum_lapse] } || vrp.services.collect{ |service| service[:minimum_lapse] }.compact.min >= 7)
    end

    def assert_vehicle_entity_only_before_work_day(vrp)
      vehicle_entity_index = vrp.preprocessing_partitions.find_index{ |partition| partition[:entity] == 'vehicle' }
      work_day_entity_index = vrp.preprocessing_partitions.find_index{ |partition| partition[:entity] == 'work_day' }
      vehicle_entity_index.nil? || work_day_entity_index.nil? || vehicle_entity_index < work_day_entity_index
    end

    def assert_deprecated_partitions(vrp)
      !((vrp.preprocessing_partition_method || vrp.preprocessing_partition_metric) && !vrp.preprocessing_partitions.empty?)
    end

    def assert_partitions_entity(vrp)
      vrp.preprocessing_partitions.empty? || vrp.preprocessing_partitions.all?{ |partition| partition[:method] != 'balanced_kmeans' || partition[:entity] }
    end

    def assert_no_partitions(vrp)
      vrp.preprocessing_partitions.empty?
    end

    def assert_no_initial_centroids_with_partitions(vrp)
      vrp.preprocessing_partitions.empty? || vrp.preprocessing_kmeans_centroids.nil?
    end

    def assert_valid_partitions(vrp)
      vrp.preprocessing_partitions.size < 3 &&
      (vrp.preprocessing_partitions.collect{ |partition| partition[:entity] }.uniq.size == vrp.preprocessing_partitions.size)
    end

    def assert_no_relation_with_scheduling_heuristic(vrp)
      (!vrp.preprocessing_first_solution_strategy || !vrp.preprocessing_first_solution_strategy.include?('periodic')) || (!vrp.relations || vrp.relations.empty?)
    end

    def assert_only_one_activity_with_scheduling_heuristic(vrp)
      vrp.services.none?{ |s| !s.activities.to_a.empty? } || (!vrp.preprocessing_first_solution_strategy || !vrp.preprocessing_first_solution_strategy.include?('periodic'))
    end

    def assert_no_route_if_clustering(vrp)
      vrp.routes.empty? || vrp.preprocessing_partitions.empty?
    end

    def assert_service_with_visit_index_in_route_if_periodic(vrp)
      !vrp.preprocessing_first_solution_strategy.to_a.include?('periodic') ||
        vrp.routes.collect{ |route| route[:mission_ids] }.flatten.all?{ |id|
          decomposition = id.split('_')
          decomposition.size >= 3 && decomposition[-1] >= decomposition[-2] && vrp.services.collect{ |s| s[:id] }.include?(decomposition[0..-3].join('_'))
        }
    end

    def assert_route_day_if_periodic(vrp)
      !vrp.preprocessing_first_solution_strategy.to_a.include?('periodic') || vrp.routes.all?{ |route| route[:day] }
    end

    def solve_synchronous?(vrp)
      false
    end

    def build_timewindows(activity, day_index)
      nil
    end

    def build_quantities(job, job_loads)
      nil
    end

    def compatible_day?(vrp, service, t_day, vehicle)
      first_day = vrp[:schedule][:range_indices] ? vrp[:schedule][:range_indices][:start] : vrp[:schedule][:range_date][:start]
      last_day = vrp[:schedule][:range_indices] ? vrp[:schedule][:range_indices][:end] : vrp[:schedule][:range_date][:end]
      (first_day..last_day).any?{ |day|
        s_ok = !t_day.nil? ? t_day == day : (service[:unavailable_visit_day_indices] || service[:unavailable_visit_date]) && service[:unavailable_visit_day_indices].include?(day)
        v_ok = vehicle[:unavailable_work_day_indices] && vehicle[:unavailable_work_day_indices].include?(day) || vehicle[:unavailable_work_date] && vehicle[:unavailable_work_date].include?(day)
        s_ok && v_ok
      }
    end

    def find_vehicle(vrp, service, timewindow)
      t_start = timewindow[:start]
      t_end = timewindow[:end]
      t_day = timewindow[:day_index]
      t_late = service[:activity][:late_multiplier]

      vrp[:vehicles].select{ |vehicle| vehicle[:timewindow] }.any?{ |vehicle|
        v_start = vehicle[:timewindow][:start]
        v_end = vehicle[:timewindow][:end]
        v_day = vehicle[:timewindow][:day_index]
        v_late = vehicle[:cost_late_multiplier] && vehicle.cost_late_multiplier.positive?
        days_compatible = v_day.nil? || t_day.nil? || v_day == t_day
        if service.unavailable_visit_day_indices&.include?(v_day)
          days_compatible = false
        end
        if v_day && v_day >= 0 && service[:unavailable_visit_day_date] && service[:unavailable_visit_day_date].include?(vrp[:schedule][:range_date][:start] + v_day)
          days_compatible = false
        end
        days_compatible = compatible_day?(vrp, service, t_day, vehicle) if v_day.nil? && vrp[:schedule] && days_compatible
        days_compatible && !(v_end && t_start && !v_late && t_start > v_end) && # Incompatible if timewindow starts after vehicle end
          !(t_end && v_start && !t_late && v_start > t_end) # Incompatible if timewindow ends before vehicle start
      } || vrp[:vehicles].none?{ |vehicle| vehicle[:timewindow] || vehicle[:sequence_timewindows] } ||
        vrp[:vehicles].select{ |vehicle| vehicle[:sequence_timewindows] }.any?{ |vehicle|
          vehicle[:sequence_timewindows].any?{ |tw|
            v_start = tw[:start]
            v_end = tw[:end]
            v_day = tw[:day_index]
            v_late = vehicle[:cost_late_multiplier] && vehicle.cost_late_multiplier.positive?
            days_compatible = v_day.nil? || t_day.nil? || v_day == t_day
            days_compatible && !(v_end && t_start && !v_late && t_start > v_end) &&
              !(t_end && v_start && !t_late && v_start > t_end)
          }
        } || vrp[:vehicles].any?{ |vehicle| vehicle[:cost_late_multiplier] && vehicle.cost_late_multiplier.positive? }
    end

    def check(vrp, matrix, unfeasible)
      if !matrix.nil?
        line_cpt = Array.new(vrp.points.size){ 0 }
        column_cpt = Array.new(vrp.points.size){ 0 }
        vrp.points.each_with_index{ |point_a, line|
          vrp.points.each_with_index{ |point_b, col|
            if matrix[point_a.matrix_index][point_b.matrix_index] >= 2**31 - 1
              line_cpt[line] += 1
              column_cpt[col] += 1
            end
          }
        }

        (0..vrp.points.size - 1).each{ |index|
          next if (column_cpt[index] == 0 || column_cpt[index] != matrix.size - 1) && (line_cpt[index] == 0 || line_cpt[index] != matrix.size - 1)
          vrp[:services].select{ |service| service[:activity][:point][:matrix_index] == vrp.points[index][:matrix_index] }.each{ |service|
            if unfeasible.none?{ |unfeas| unfeas[:service_id] == service[:id] }
              add_unassigned(unfeasible, vrp, service, 'Unreachable')
            end
          }
        }
      end

      unfeasible
    end

    def add_unassigned(unfeasible, vrp, service, reason)
      return unfeasible if unfeasible.any?{ |unfeas| unfeas[:service_id] == service[:id] }

      unfeasible << (0..service.visits_number).collect{ |index|
        service_unassigned = unfeasible.find{ |una| una[:original_service_id] == service[:id] }
        service_unassigned[:reason] += " && #{reason}" if service_unassigned
        next if service_unassigned || service.visits_number.positive? && index.zero?

        {
          original_service_id: service[:id],
          service_id: vrp.scheduling? ? "#{service.id}_#{index}_#{service.visits_number}" : service[:id],
          point_id: service[:activity] ? service[:activity][:point_id] : nil,
          detail: {
            lat: service[:activity] && service[:activity][:point][:location] ? service[:activity][:point][:location][:lat] : nil,
            lon: service[:activity] && service[:activity][:point][:location] ? service[:activity][:point][:location][:lon] : nil,
            setup_duration: service[:activity] ? service[:activity][:setup_duration] : nil,
            duration: service[:activity] ? service[:activity][:duration] : nil,
            timewindows: service[:activity][:timewindows] ? service[:activity][:timewindows].collect{ |tw| {start: tw[:start], end: tw[:end] }} : [],
            quantities: service[:quantities] ? service[:quantities].collect{ |qte| { unit: qte[:unit].id, value: qte[:value] } } : nil
          },
          reason: reason
        }
      }.compact
      unfeasible.flatten!
    end

    def compute_vehicles_shift(vehicles)
      max_shift = vehicles.collect{ |vehicle|
        if vehicle.timewindow&.start && vehicle.timewindow&.end
          vehicle.timewindow.end - vehicle.timewindow.start
        elsif vehicle.sequence_timewindows.all?{ |tw| tw.start && tw.end }
          vehicle.sequence_timewindows.collect{ |tw| tw.end - tw.start }.max
        end
      }
      max_shift.include?(nil) ? nil : max_shift.max
    end

    def compute_vehicles_capacity(vrp)
      capacities = {}
      vrp.units.each{ |unit|
        this_limits = vrp.vehicles.collect{ |v| v.capacities ? v.capacities.find{ |capacity| capacity.unit_id == unit.id }&.limit : nil }.flatten
        capacities[unit.id] = this_limits.include?(nil) ? nil : this_limits.max
      }

      capacities
    end

    def clean_data(vrp)
      if vrp.resolution_floating_precision.zero?
        vrp.services.map{ |service| service.activity.duration = service.activity.duration.ceil }
      else
        vrp.services.map{ |service| service.activity.duration = service.activity.duration.round(vrp.resolution_floating_precision) }
      end
    end

    def detect_unfeasible_services(vrp)
      unfeasible = []
      vehicle_max_shift = compute_vehicles_shift(vrp.vehicles)
      vehicle_max_capacities = compute_vehicles_capacity(vrp)
      check_sticky_skills = vrp.services.any?{ |service| service.sticky_vehicles.size > 1 } # if only one sticky, each service will be assigned to one vehicle, we ignore uncompatible skill
      vehicle_available_skills = vrp.vehicles.collect(&:skills).flatten.uniq

      vrp.services.each{ |service|
        # TODO : detect with grape (needs grape update)
        add_unassigned(unfeasible, vrp, service, 'Visits number is 0') if service.visits_number.zero?

        service.quantities.each{ |qty|
          add_unassigned(unfeasible, vrp, service, 'Unsufficient capacity in vehicles') if vehicle_max_capacities[qty.unit_id] && qty.value && vehicle_max_capacities[qty.unit_id] < qty.value
        }

        # no need to check service and vehicle skills compatibility
        # if no vehicle has the skills for a given service we consider service's skills are unconsistent for current problem

        if check_sticky_skills && !service.skills.empty?
          if service.sticky_vehicles.none?{ |vehicle| (service.skills & vehicle_available_skills).empty? || vehicle.skills.any?{ |alternative| (service.skills & alternative).size == (service.skills & vehicle_available_skills).size } }
            add_unassigned(unfeasible, vrp, service, 'Incompatibility between service skills and sticky_ids')
          end
        end

        next if service.activity.nil? && service.activities.empty?

        duration = service.activity ? service.activity.duration : service.activities.collect(&:duration).min
        add_unassigned(unfeasible, vrp, service, 'Duration bigger than any vehicle timewindow shift') if vehicle_max_shift && duration > vehicle_max_shift

        timewindows = service.activity ? service.activity.timewindows : service.activities.collect(&timewindows)
        add_unassigned(unfeasible, vrp, service, 'No vehicle with compatible timewindow') if !timewindows.empty? && timewindows.none?{ |tw| find_vehicle(vrp, service, tw) }

        # unconsistency for planning
        next if !vrp.scheduling?

        nb_days = vrp.schedule_indices[1] - vrp.schedule_indices[0] + 1
        add_unassigned(unfeasible, vrp, service, 'Unconsistency between visit number and minimum lapse') if service.visits_number && service.visits_number > 1 && service.minimum_lapse && nb_days - (service.visits_number - 1) * service.minimum_lapse <= 0
      }

      unfeasible
    end

    def check_distances(vrp, unfeasible)
      vrp[:matrices].each{ |matrix|
        unfeasible = check(vrp, matrix[:time], unfeasible)
        unfeasible = check(vrp, matrix[:distance], unfeasible)
        unfeasible = check(vrp, matrix[:value], unfeasible)
      }

      # check distances from vehicle depot is feasible
      vrp.services.each{ |service|
        index = service.activity.point.matrix_index
        found = vrp.vehicles.find{ |vehicle|
          if vehicle.start_point_id && vehicle.end_point_id &&
            (vehicle.cost_time_multiplier > 0 && (vehicle.timewindow && vehicle.timewindow.start && vehicle.timewindow.end || vehicle.sequence_timewindows && !vehicle.sequence_timewindows.empty?) ||
            vehicle.cost_distance_multiplier > 0 && vehicle.distance)

            start_index = vehicle.start_point.matrix_index
            end_index = vehicle.end_point.matrix_index

            metric = vehicle.cost_time_multiplier > 0 ? :time : :distance
            cost = vrp.matrices[0][metric][start_index][index] + vrp.matrices[0][metric][index][end_index]

            if metric == :time
              vehicle_available_time = vehicle.timewindow.end - vehicle.timewindow.start if vehicle.timewindow
              vehicle_available_time = vehicle.sequence_timewindows.collect{ |tw| tw.end - tw.start }.max if vehicle.sequence_timewindows && !vehicle.sequence_timewindows.empty?
              vehicle_available_time >= cost
            else
              vehicle.distance >= cost
            end
          else
            true
          end
        }
        check_approach_return = vrp.matrices.all?{ |matrix| matrix[:time] } && vrp.vehicles.all?{ |vehicle|
          matrix = vrp.matrices.find{ |matrix| matrix.id == vehicle.matrix_id }
          earliest_arrival = vehicle.timewindow.start + matrix[:time][vehicle.start_point.matrix_index][index] if vehicle.start_point_id && vehicle.timewindow && vehicle.timewindow.start
          latest_arrival = vehicle.timewindow.end - service.activity.duration - matrix[:time][index][vehicle.end_point.matrix_index] if vehicle.end_point_id && vehicle.timewindow && vehicle.timewindow.end

          check_approach = (service.activity.late_multiplier.nil? || service.activity.late_multiplier == 0) && !service.activity.timewindows.empty? && service.activity.timewindows.all?{ |tw|
            tw.end && earliest_arrival && earliest_arrival > tw.end
          }
          check_return = (vehicle.cost_late_multiplier.nil? || vehicle.cost_late_multiplier == 0) && !service.activity.timewindows.empty? && service.activity.timewindows.all?{ |tw|
            tw.start && latest_arrival && tw.start > latest_arrival
          }
          check_approach || check_return || latest_arrival && earliest_arrival && earliest_arrival > latest_arrival
        }

        if !found && unfeasible.none?{ |unfeas| unfeas[:service_id] == service[:id] }
          add_unassigned(unfeasible, vrp, service, 'Unreachable')
        elsif check_approach_return
          add_unassigned(unfeasible, vrp, service, 'Service cannot be reached within its timewindows')
        end
      }

      unfeasible
    end

    def simplify_constraints(vrp)
      if vrp[:vehicles] && !vrp[:vehicles].empty?
        vrp[:vehicles].each{ |vehicle|
          if (vehicle[:force_start] || vehicle[:shift_preference] == "force_start") && vehicle[:duration] && vehicle[:timewindow]
            vehicle[:timewindow][:end] = vehicle[:timewindow][:start] + vehicle[:duration]
            vehicle[:duration] = nil
          end
        }
      end

      vrp
    end

    def kill
    end
  end
end
