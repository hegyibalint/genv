# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

function __genv_get_cmd --description="Returns the environment's Gradle binary"
    echo -n "$gradle_env_dist_dir/bin/gradle -Dgradle.user.home=$gradle_env_home_dir"
end

# =============================================================================
# MODIFICATION FUNCTIONS
# =============================================================================

function __genv_create -d="Creates a new Gradle environment"
    argparse -n "genv create" h/help a/activate i/install -- $argv
    or return
    set -l env $argv[1]

    if set -ql _flag_help
        echo "Usage: genv create [options] <env>"
        echo "Creates a new Gradle environment named <env>"
        echo ""
        echo "Options:"
        echo "  -a, --activate  Activates the environment after creation"
        echo "  -i, --install   Installs a distribution after creation (implies --activate)"
        return 0
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

    if set -ql _flag_activate; or set -ql _flag_install
        __genv_activate $env
    end
    if set -ql _flag_install
        __genv_install $env
    end
end

function __genv_delete --description="Deletes a Gradle environment"
    argparse -n "genv delete" h/help a/all -- $argv
    set -l env $argv[1]

    if set -ql _flag_help
        echo "Usage: genv delete [options] <env>"
        echo "Deletes a Gradle environment named <env>"
        echo ""
        echo "Options:"
        echo "  -a, --all  Deletes all the environments"
        return 0
    end

    if set -ql _flag_all
        read -l -P 'Do you want to delete all environments? [y/N] ' confirm
        if test "$confirm" = y
            # Test if gradle_envs_dir is set
            # This is a safety measure, to prevent accidental deletion of the whole filesystem
            if set -q gradle_envs_dir
                rm -rf $gradle_envs_dir
                echo "All Gradle environments are destroyed"
                return 0
            else
                set_color red
                echo "Error: gradle_envs_dir is not set, no environments are deleted"
                set_color normal
                return 2
            end
        else
            set_color red
            echo "Cancelling operation"
            set_color normal
            return 1
        end
    end

    if test -z "$env"
        set_color red
        echo "No environment name is specified"
        set_color normal
        return 1
    end

    set -l gradle_env_dir "$gradle_envs_dir/$env"
    if test -d "$gradle_env_dir"
        rm -rf "$gradle_env_dir"
        echo "Gradle environment '$env' destroyed"
    else
        set_color red
        echo "Gradle environment '$env' not found"
        set_color normal
        return 1
    end
end

# =============================================================================
# ACTIVITY FUNCTIONS
# =============================================================================

function __genv_activate -a env -d "Activates a Gradle environment"
    argparse -n "genv activate" h/help -- $argv

    if set -ql _flag_help
        echo "Usage: genv activate [options] <env>"
        echo "Activates a Gradle environment named <env>"
        return 0
    end

    if test -z "$env"
        echo "No environment name is specified"
        return 1
    end

    if not test -d "$gradle_envs_dir/$env"
        set_color red
        echo "Gradle environment not found"
        set_color normal
        echo -n "You can create it calling: '"
        set_color yellow
        echo -n "genv create $env"
        set_color normal
        echo "'"
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

    set_color black
    echo "The 'gradle' command is aliased with:"
    echo " -> $gradle_cmd $gradle_cmd_args {other arguments}"
    set_color normal
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
    if not set -q gradle_env
        set_color red
        echo "No environment is activated"
        set_color normal
        return 1
    end

    if not test -f "./gradlew"
        set_color red
        echo "No './gradlew' executable found; are you in the root of a Gradle project?"
        set_color normal
        return 1
    end

    # Installs the distribution into the environment's 'dist' directory
    ./gradlew install -Pgradle_installPath="$gradle_env_dist_dir"
end

# =============================================================================
# EXECUTION FUNCTIONS
# =============================================================================

function __genv_execute --description="Executes a Gradle run with the activated environment"
    if not set -q gradle_env
        echo "No environment is activated"
        return 1
    end

    set -l gradle_cmd (__genv_get_cmd) "$argv"
    # Puts all the other arguments incoming onto the args

    echo "============================================================================="
    __genv_print_info
    echo "Command: $gradle_cmd "
    echo "============================================================================="

    set -l gradle_bin "$gradle_env_dist_dir/bin/gradle"
    if not test -x $gradle_bin
        set_color red
        echo "No 'gradle' binary is found at the path '$gradle_env_dist_dir/bin'"
        set_color normal
        echo "Is the distribution installed with 'genv install'?"
        return 1
    end

    eval $gradle_cmd $gradle_cmd_args $cmd
end

# =============================================================================
# DESCRIBE FUNCTIONS
# =============================================================================

function __genv_print_status --description="Prints the status of the environment"
    if not set -q gradle_env
        set_color red
        echo "No environment is activated"
        set_color normal
        return 1
    else
        echo "Gradle environment: '$gradle_env'"
        echo "Environment directory: '$gradle_env_dir'"
    end
end

function __genv_print_info --description="Installs a Gradle distribution into the environment"
    argparse -n genv h/help -- $argv

    if set -ql _flag_help
        echo "Usage: genv <command>"
        echo "  create:     Creates a new Gradle environment"
        echo "  delete:     Deletes a Gradle environment"
        echo "  activate:   Activates a Gradle environment"
        echo "  deactivate: Deactivates a Gradle environment"
        echo "  install:    Installs a distribution into the environment"
        echo "  status:     Prints the status of the environment"
        echo ""
        echo "see 'genv <command> --help' for more information"
        return 0
    end

    echo "Version: $genv_version"
end

# =============================================================================
# ENTRY POINT
# =============================================================================

function genv --description="Handles Gradle environments"
    switch $argv[1]
        case create
            __genv_create $argv[2..]
        case delete
            __genv_delete $argv[2..]
        case activate
            __genv_activate $argv[2..]
        case deactivate
            __genv_deactivate $argv[2..]
        case install
            __genv_install $argv[2..]
        case execute
            __genv_execute $argv[2..]
        case status
            __genv_print_status $argv[2..]
        case '*'
            __genv_print_info $argv[1..]
    end
end
