# Get the IP address from WSL
$WSL_CLIENT = bash.exe -c "ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'";
$WSL_CLIENT -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';
$WSL_CLIENT = $matches[0];

# Map the drive. -Persist is necessary to expose the drive outside the PSSession.
Remove-PSDrive -Name S -Force
New-PSDrive -Name S -PSProvider FileSystem -Root "\\$WSL_CLIENT\Projects" -Persist
