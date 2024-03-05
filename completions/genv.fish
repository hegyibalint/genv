set -l commands create delete activate deactivate install

function __genv_list_envs --description "Finds all the environments available, and formats them into fish-acceptable completion format"
    # TODO: Fix case, when directory doesn't exist
    for env in (find $gradle_envs_dir -maxdepth 1 -not -path $gradle_envs_dir -type d -exec basename {} \;)
        printf "%s\tEnvironment\n" $env
    end
end

# Top level commands
complete -c genv -n "not __fish_seen_subcommand_from $commands" -x -a create -d "Creates an environment"
complete -c genv -n "not __fish_seen_subcommand_from $commands" -x -a delete -d "Deletes an environment"
complete -c genv -n "not __fish_seen_subcommand_from $commands" -x -a activate -d "Activates an environment"
complete -c genv -n "not __fish_seen_subcommand_from $commands" -x -a install -d "Installs a distribution"

# Create subcommand
complete -c genv -n "__fish_seen_subcommand_from create" -l activate -s a -d "Activates the environment after creation"
complete -c genv -n "__fish_seen_subcommand_from create" -l install -s i -d "Installs a distribution after creation (implies --activate)"
complete -c genv -n "__fish_seen_subcommand_from create" -f
# Delete subcommand
complete -c genv -n "__fish_seen_subcommand_from delete" -l all -s a -d "Deletes all the environments"
complete -c genv -n "__fish_seen_subcommand_from delete" -x -a "(__genv_list_envs)"
# Activate subcommand
complete -c genv -n "__fish_seen_subcommand_from activate" -x -a "(__genv_list_envs)"
# Install subcommand
complete -c genv -n "__fish_seen_subcommand_from install"
