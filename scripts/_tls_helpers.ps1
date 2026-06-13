# AVOV - Helper TLS para certificados autofirmados en validaciones locales
function Enable-AvovTlsSkip {
    if ($script:AvovTlsSkipEnabled) { return }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {
        param($sender, $certificate, $chain, $sslPolicyErrors)
        return $true
    }
    $script:AvovTlsSkipEnabled = $true
}
