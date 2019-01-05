function send_email {
    $mail_message = New-Object system.net.mail.mailmessage
    $mail_message.From = New-Object MailAddress("name@something", "name@something")
    $mail_message.To.add("email@email.com")
    $mail_message.Subject = "Alert"
    $mail_message.Body = $email_body
    $mail_message.IsBodyHTML = $true

    $smtp_client = New-Object Net.Mail.SmtpClient("smtp.email.com", 587)
    $smtp_client.EnableSsl = $true
    $smtp_client.Credentials = New-Object System.Net.NetworkCredential("username", "password")
    $smtp_client.Send($mail_message)
}


function run_pass($saved_event_id) {
    $email_body = ""
    $send_email_flag = $false

    $all_events = Get-EventLog -logname "Application" |
        ?{$_.eventid -eq "ID" -and $_.Message -like "*something*"}

    $last_event_id = ($all_events).Index | Sort -Descending | Select -First 1

    # Write-Host "last_event_id:  $last_event_id"
    # Write-Host "saved_event_id: $saved_event_id"

    if ($last_event_id -gt $saved_event_id) {
        $all_events | ForEach-Object -Process {
            if ($_.Index -gt $saved_event_id) {
                # Get process name line from event message
                $process_name_line = $_.Message -Split "`n" | Select-String -Pattern "Process Name:" -CaseSensitive
                # Extract process name from event message line
                $process_name = [regex]::match($process_name_line,'Process Name:\s*(.+)').Groups[1].Value

                if (($process_name -NotLike '*something*') -And ($process_name -NotLike '*something*')) {
                    $send_email_flag = $true

                    # Add event to email body
                    $email_body = $email_body + "<b>[$($_.TimeGenerated)]</b> $process_name" + "`n<br>"
                }
            }
        }
    }

    if ($send_email_flag) {
        # Write-Host "Sending email..."
        send_email
    }

    return $last_event_id
}


while ($true) {
    $saved_event_id = (&{If (Test-Path "history.xml") {Import-Clixml "history.xml"} Else {0}})

    $saved_event_id = run_pass $saved_event_id

    $saved_event_id | Export-Clixml "history.xml"

    Start-Sleep -seconds 3600
}