#!/bin/bash

# Forces bash's time to output real time in raw seconds versus a more human friendly string
TIMEFORMAT="%R"

function run_test {
    # this funky bit of grouping below is to make sure we capture the time builtin's output.
    # the time builtin outputs to stderr, so we wrap the builtin in a group and capture 
    # the groups stderr in the results file
    {
        time { 
            terraform apply  -auto-approve 2>&1 | tee -a logs
        }
    } 2>> results 
    {
        time {
            terraform destroy -auto-approve  2>&1 | tee -a logs
        }
    } 2>> destroy_results
}


num_runs="${1-1}"
for i in $(seq 1 ${num_runs}); do
    run_test
done
