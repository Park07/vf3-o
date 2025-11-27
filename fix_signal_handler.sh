#!/bin/bash

# Find the line number where SIGTERM handler starts
LINE=$(grep -n "case SIGTERM:" main.cpp | cut -d: -f1)

# Create a patch for the signal handler
cat > signal_fix.patch << 'PATCH'
                case SIGTERM:
                        if (global_matching_engine_ptr != nullptr) {
                                struct timeval end_time;
                                gettimeofday(&end_time, NULL);
                                double elapsed = (end_time.tv_sec - global_start_time.tv_sec) +
                                                (end_time.tv_usec - global_start_time.tv_usec) / 1000000.0;
                                auto* engine = static_cast<vflib::MatchingEngine<state_t>*>(global_matching_engine_ptr);
                                std::cout << engine->GetSolutionsCount() << " 0 " << elapsed << " TIMEOUT\n";
                        } else {
                                std::cout << "Terminated \n";
                        }
                        exit(-1);
PATCH

echo "Apply this fix manually to main.cpp at the SIGTERM case"
echo "The signal handler needs to output: <count> 0 <time> TIMEOUT"
