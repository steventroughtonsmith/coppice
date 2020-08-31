<?php
$keypair = openssl_pkey_new([
	'private_key_bits' => 2048,
	"private_key_type" => OPENSSL_KEYTYPE_RSA,
]);

openssl_pkey_export($keypair, $private_key_pem);

$details = openssl_pkey_get_details($keypair);
$public_key_pem = $details['key'];

file_put_contents('private_key.pem', $private_key_pem);
file_put_contents('public_key.pem', $public_key_pem);
?>

<html>
<head>
<meta charset="utf-8">
</head>
<body>
	<p>Generated Key Pair</p>
<p>Now do the following (from https://stackoverflow.com/questions/10579985/how-can-i-get-seckeyref-from-der-pem-file)</p>
<pre>
//Create a certificate signing request with the private key
openssl req -new -key private_key.pem -out rsaCertReq.csr

//Create a self-signed certificate with the private key and signing request
openssl x509 -req -days 3650 -in rsaCertReq.csr -signkey private_key.pem -out rsaCert.crt

//Export the private key and certificate to p12 file
openssl pkcs12 -export -out private_key.p12 -inkey private_key.pem -in rsaCert.crt
</pre>

<p><b>Be sure to set a password</b></p>
</body>
</html>