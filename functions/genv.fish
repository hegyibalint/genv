# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

function __genv_get_cmd --description="Returns the environment's Gradle binary"
    echo -n "$gradle_env_dist_dir/bin/gradle"
end

function __genv_get_cmd_args --description="Returns the mandatory parameters of a Gradle execution"
    echo -n "-Dgradle.user.home=$gradle_env_home_dir"
end

# =============================================================================
# MODIFICATION FUNCTIONS
# =============================================================================

function __genv_create --argument env --description="Creates a new Gradle environment"
    if test -z "$env"
        echo "No environment name is specified"
        return 1
    end

    # Create the environments' parent directory, if it doesn't exist
    if not test -d "$gradle_envs_dir"
        mkdir "$gradle_envs_dir"
    end

    set -l gradle_env_dir "$gradle_envs_dir/$env"
    if test -d "$gradle_env_dir"
        echo "Gradle environment already exists at '$gradle_env_dir'"
        return 1
    else
        echo "Creating new Gradle environment '$env' at '$gradle_env_dir'"
        # Create the environment's root directory
        mkdir -p "$gradle_env_dir"
        # Create directory for the Gradle distribution
        mkdir "$gradle_env_dir/dist"
        # Create directory for the Gradle home
        mkdir "$gradle_env_dir/home"
    end
end

function __genv_delete --argument env --description="Deletes a Gradle environment"
    if test -z "$env"
        echo "No environment name is specified"
        return 1
    end

    set -l gradle_env_dir "$gradle_envs_dir/$env"
    if test -d "$gradle_env_dir"
        rm -rf "$gradle_env_dir"
        echo "Gradle environment '$env' destroyed"
    else
        echo "Gradle environment '$env' not found"
        return 1
    end
end

# =============================================================================
# ACTIVITY FUNCTIONS
# =============================================================================

function __genv_activate --argument env --description="Activates a Gradle environment"
    if test -z "$env"
        echo "No environment name is specified"
        return 1
    end

    if not test -d "$gradle_envs_dir/$env"
        echo "Gradle environment not found"
        return 1
    end

    set -g gradle_env "$env"
    set -g gradle_env_dir "$gradle_envs_dir/$env"
    set -g gradle_env_dist_dir "$gradle_env_dir/dist"
    set -g gradle_env_home_dir "$gradle_env_dir/home"

    echo "Gradle environment '$gradle_env' activated"

    # Override the 'gradle' executable, to a special function,
    # which will redirect it to the env's home directory
    alias gradle="genv execute"

    set -l gradle_cmd (__genv_get_cmd)
    set -l gradle_cmd_args (__genv_get_cmd_args "{passed arguments}")

    echo "The 'gradle' command is aliased with:"
    echo " -> $gradle_cmd $gradle_cmd_args {other arguments}"
end

function __genv_deactivate --description "Deactivates a Gradle environment"
    if not set -q gradle_env
        echo "No environment is activated"
        return 1
    else
        echo "Gradle environment '$gradle_env' deactivated"
        set -e gradle_env
        set -e gradle_env_dir
        set -e gradle_env_dist_dir
        set -e gradle_env_home_dir
        functions -e gradle
    end
end

function __genv_install --description="Installs a Gradle distribution into the environment"
    # Exit, if the environment is not set
    if not set -q gradle_env
        echo "No environment is activated"
        return 1
    end

    # Installs the distribution into the environment's 'dist' directory
    ./gradlew install -Pgradle_installPath="$gradle_env_dist_dir"
end

# =============================================================================
# EXECUTION FUNCTIONS
# =============================================================================

function __genv_execute --argument cmd --description="Executes a Gradle run with the activated environment"
    if not set -q gradle_env
        echo "No environment is activated"
        return 1
    end

    set -l gradle_cmd (__genv_get_cmd)
    set -l gradle_cmd_args (__genv_get_cmd_args)

    echo "============================================================================="
    __genv_print_info
    echo "Command: $gradle_cmd $gradle_cmd_args $cmd" 
    echo "============================================================================="

    set -l gradle_bin "$gradle_env_dist_dir/bin/gradle"
    if not test -x $gradle_bin
        echo "No 'gradle' binary is found at the path '$gradle_env_dist_dir/bin'"
        echo "Is the distribution installed with 'genv install'?"
        return 1
    end

    eval $gradle_cmd $gradle_cmd_args $cmd
end

# =============================================================================
# DESCRIBE FUNCTIONS
# =============================================================================

function __genv_print_info --description="Installs a Gradle distribution into the environment"
    echo "Version: $genv_version"
    echo "Environment directory: "

    if not set -q gradle_env
        echo "No environment is activated"
        return 1
    else
        echo "Gradle environment: '$gradle_env'"
        echo "Environment directory: '$gradle_env_dir'"
    end
end

# =============================================================================
# ENTRY POINT
# =============================================================================

function genv --description="Handles Gradle environments" --argument cmd
    switch $cmd
        case create
            __genv_create "$argv[2..-1]"
        case delete
            __genv_delete "$argv[2..-1]"
        case activate
            __genv_activate "$argv[2..-1]"
        case deactivate
            __genv_deactivate
        case install
            __genv_install "$argv[2..-1]"
        case execute
            __genv_execute "$argv[2..-1]"
        case '*'
            __genv_print_info
    end
end
