# Define the application to open and its arguments
$appPath = "Your/Application/Path/Here"  # Change this to the path of your application
$appArguments = "--AnyAppArgumentsHere"  # Change this to the arguments you want to pass
$adapterName = "YourNetworkAdapterName"  # Name of the network adapter

# Function to check if the network adapter is connected
function Is-AdapterConnected {
    $adapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue
    return $adapter.Status -eq "Up"
}

# Check if the adapter is connected
if (Is-AdapterConnected) {
    # If connected, open the application with arguments
    Start-Process $appPath -ArgumentList $appArguments
} else {
    # If disconnected, prompt the user
    Add-Type -AssemblyName System.Windows.Forms
    $message = "Your X Adapter is disconnected. Would you like to open the app anyway?"
    $caption = "Adapter Status"
    $result = [System.Windows.Forms.MessageBox]::Show($message, $caption, [System.Windows.Forms.MessageBoxButtons]::YesNo)

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        # If user selects Yes, open the application with arguments
        Start-Process $appPath -ArgumentList $appArguments
    }
}
