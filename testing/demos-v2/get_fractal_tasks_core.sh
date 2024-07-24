check_exit_code() {
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "Error: $1 (EXIT_CODE=$EXIT_CODE)"
        exit 1
    fi
}

source config.env
echo "FRACTAL_TASKS_CORE_V2_RELEASE=$FRACTAL_TASKS_CORE_V2_RELEASE"
echo "FRACTAL_TASKS_CORE_V2_GIT=$FRACTAL_TASKS_CORE_V2_GIT"
MANIFEST_JSON=https://raw.githubusercontent.com/fractal-analytics-platform/fractal-tasks-core/$FRACTAL_TASKS_CORE_V2_GIT/fractal_tasks_core/__FRACTAL_MANIFEST__.json
echo $MANIFEST_JSON
if [ -z "${FRACTAL_TASKS_CORE_V2_RELEASE}" ]; then
    curl -o /fractal-demos-v2/examples/FRACTAL_MANIFEST.json $MANIFEST_JSON 
    if [ -z "${FRACTAL_TASKS_CORE_V2_GIT}" ]; then
        # Case 1: no release, no git
        fractal task collect-custom fractal-tasks-core /fractal-tasks-venv/bin/python /fractal-demos-v2/examples/FRACTAL_MANIFEST.json --package-root /fractal-tasks-venv/lib/python3.10/site-packages/fractal_tasks_core/ 
    else
        # Case 2: only git set
        git clone https://github.com/fractal-analytics-platform/fractal-tasks-core.git
        cd fractal-tasks-core
        git checkout $FRACTAL_TASKS_CORE_V2_GIT
        check_exit_code "Checking out to fractal-tasks-core@$FRACTAL_TASKS_CORE_V2_GIT"

        curl -sSL https://install.python-poetry.org | python -
        check_exit_code "Poetry installation"

        /root/.local/bin/poetry build

        WHL=`ls dist/*.whl`
        check_exit_code "File .whl not found"
        ABS_WHL="$(pwd)/$WHL"

        cd ..
        fractal task collect-custom fractal-tasks-core /fractal-tasks-venv/bin/python /fractal-demos-v2/examples/FRACTAL_MANIFEST.json --package-root /fractal-tasks-venv/lib/python3.10/site-packages/fractal_tasks_core/ 
    fi
else
    if [ -z "${FRACTAL_TASKS_CORE_V2_GIT}" ]; then
        # Case 3: only release set
        fractal task collect fractal-tasks-core --package-extras fractal-tasks --package-version $FRACTAL_TASKS_CORE_V2_RELEASE    else
        # Case 4: both release and git set
        echo "Error: cannot set both FRACTAL_TASKS_CORE_V2_RELEASE and FRACTAL_TASKS_CORE_V2_GIT."
        exit 1
    fi
fi
