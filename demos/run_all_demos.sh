#!/bin/bash

echo "START run_all_demos.sh"

# Due to how fractal-demos scripts are written, we should have a .fractal.env
# file also in 00_user_setup
cp .fractal.env 00_user_setup
cp .fractal.env 01_cardio_tiny_dataset

# Copy images from Resources folder
mkdir images
cp -r /home/fractal_share/Resources/images/10.5281_zenodo.8287221 images/

# Trigger task collection
source config.env
echo "FRACTAL_TASKS_CORE_RELEASE=$FRACTAL_TASKS_CORE_RELEASE"
echo "FRACTAL_TASKS_CORE_GIT=$FRACTAL_TASKS_CORE_GIT"
if [ -z "${FRACTAL_TASKS_CORE_RELEASE}" ]; then
    if [ -z "${FRACTAL_TASKS_CORE_GIT}" ]; then
        # Case 1: no release, no git
        fractal task collect fractal-tasks-core --package-extras fractal-tasks
    else
        # Case 2: only git set
        # TODO: git clone, git checkout, install poetry, poetry build, collect from local wheel file
        echo "Error: FRACTAL_TASKS_CORE_GIT not supported" && exit 1
    fi
else
    if [ -z "${FRACTAL_TASKS_CORE_GIT}" ]; then
        # Case 3: only release set
        fractal task collect fractal-tasks-core --package-extras fractal-tasks --package-version $FRACTAL_TASKS_CORE_RELEASE
    else
        # Case 4: both release and git set
        echo "Error: cannot set both FRACTAL_TASKS_CORE_RELEASE and FRACTAL_TASKS_CORE_GIT."
        exit 1
    fi
fi

# Wait for task collection to be complete
while [ "$(fractal task list)" == "[]" ]; do
    echo "No task available, wait 10 seconds.";
    sleep 10;
done

# Enter 01_cardio_tiny_dataset folder
cd 01_cardio_tiny_dataset

# Run example 01 and capture exit code
echo "START examples/01 API calls"
TMPFILE="tmp_01_api.txt"
./run_example.sh >> $TMPFILE 2>&1
API_EXITCODE=$?
cat $TMPFILE

# Check exit code
if [ $API_EXITCODE -ne 0 ]; then
    echo "Error: API_EXITCODE=$API_EXITCODE"
    exit 1
fi

# Parse temporary file to extract PROJECT_ID and JOB_ID
PROJECT_ID=$(cat $TMPFILE | grep "PROJECT_ID" | cut -d '=' -f 2)
JOB_ID=$(cat $TMPFILE | grep "JOB_ID" | cut -d '=' -f 2)
echo "PROJECT_ID=$PROJECT_ID"
echo "JOB_ID=$JOB_ID"

# Wait for job to be done or failed
while true; do
    STATUS_LINE=$(fractal job show $PROJECT_ID $JOB_ID | grep "status")
    echo $STATUS_LINE
    if [[ "$STATUS_LINE" == *done* || "$STATUS_LINE" == *failed* ]]; then
        break
    fi
    sleep 1
done

# Check job status, once again
fractal job show $PROJECT_ID $JOB_ID
echo "END examples/01 API calls"

# Start output validation
echo "START examples/01 output validation"
TMPFILE="tmp_01_validation.txt"
python validate_results.py >> $TMPFILE 2>&1
VALIDATION_EXIT_CODE=$?
cat $TMPFILE

# Check exit code
if [ $VALIDATION_EXIT_CODE-ne 0 ]; then
    echo "Error: VALIDATION_EXIT_CODE=$VALIDATION_EXIT_CODE"
    exit 1
fi

echo "END examples/01 output validation"
echo

echo "API_EXITCODE=$API_EXITCODE"
echo "VALIDATION_EXIT_CODE=$VALIDATION_EXIT_CODE"
echo "END run_all_demos.sh"
