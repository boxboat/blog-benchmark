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
            # Let's make sure all the instances we created are actually ready for use before
            # we call time.  A caveat to this methos is that this wait call will only poll
            # once every 15 seconds.
            aws --region=${AWS_DEFAULT_REGION-us-east-2} ec2 wait instance-status-ok --instance-ids \
                $(terraform output -json | jq -r "[ .[].value ] | flatten | join(\" \")") 2>&1 | tee -a logs
        }
    } 2>> results 
    {
        time {
            terraform destroy -auto-approve 2>&1 | tee -a logs
            # same as above, but we're just waiting for the instances to truly be terminated
            aws --region=${AWS_DEFAULT_REGION-us-east-2} ec2 wait instance-terminated --instance-ids \
                $(terraform output -json | jq -r "[ .[].value ] | flatten | join(\" \")") 2>&1 | tee -a logs
        }
    } 2>> destroy_results
}


num_runs="${1-1}"
for i in $(seq 1 ${num_runs}); do
    run_test
done
