plugin: azure_rm
include_vm_resource_groups:
    - ${ resource_group_name }

conditional_groups:
    all: true
    domain_controllers: "'dc' in computer_name"
    windows_servers: "'WindowsServer' in image.offer"
    windows_clients: "'MicrosoftWindowsDesktop' in image.publisher"


hostvars_expressions:
    windows_servers:
        ansible_connection: winrm
        ansible_winrm_transport: ntlm
        ansible_winrm_scheme: http
        ansible_winrm_server_cert_validation: ignore
        ansible_port: 5985
        ansible_user: ${ admin_username }
        ansible_password: ${ admin_password }
    domain_controllers:
        ansible_connection: winrm
        ansible_winrm_transport: ntlm
        ansible_winrm_scheme: http
        ansible_winrm_server_cert_validation: ignore
        ansible_port: 5985
        ansible_user: ${ admin_username }
        ansible_password: ${ admin_password }
    windows_clients:
        ansible_connection: winrm
        ansible_winrm_transport: ntlm
        ansible_winrm_scheme: http
        ansible_winrm_server_cert_validation: ignore
        ansible_port: 5985
        ansible_user: ${ admin_username }
        ansible_password: ${ admin_password }    