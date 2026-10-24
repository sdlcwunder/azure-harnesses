workspace "Azure harness" "C4 model of the Azure harness." {

    !identifiers hierarchical

    model {
        developer = person "Developer" "Builds and runs the harness, and reviews the agent's work."

        harness = softwareSystem "Azure harness" "Lets a coding agent work against Azure without access to production credentials." {
            devContainer = container "Dev container" "Developer tools and the coding agent, isolated from the host." "Docker, VS Code Dev Containers"
            agent = container "Coding agent" "Plans and makes code and infrastructure changes." "Claude Code"
            azure = container "Restricted Azure environment" "Sandbox subscription with scoped permissions where the agent deploys and tests." "Azure"
            repo = container "GitHub repository" "Source of truth for code, infrastructure and docs." "GitHub"
        }

        developer -> harness.devContainer "Works in" "VS Code IDE"
        developer -> harness.repo "Reviews pull requests in" "HTTPS"
        harness.devContainer -> harness.agent "Runs"
        harness.agent -> harness.azure "Deploys to and tests against" "Azure CLI"
        harness.agent -> harness.repo "Pushes branches and opens pull requests to" "Git, GitHub API"
    }

    views {
        systemContext harness "SystemContext" "Who uses the Azure harness." {
            include *
        }

        container harness "Containers" "The parts of the Azure harness and how they interact." {
            include *
        }

        styles {
            element "Person" {
                shape person
            }
        }
    }
}
