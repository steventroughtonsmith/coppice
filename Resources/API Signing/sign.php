<?php
// $keypair = openssl_pkey_new([
// 	'private_key_bits' => 2048,
// 	"private_key_type" => OPENSSL_KEYTYPE_RSA,
// ]);

// openssl_pkey_export($keypair, $private_key_pem);

// $details = openssl_pkey_get_details($keypair);
// $public_key_pem = $details['key'];

// file_put_contents('private_key.pem', $private_key_pem);
// file_put_contents('public_key.pem', $public_key_pem);

// $data = ['payload' => ['foo' => 'bar', 'baz' => 3], 'signature' => 'asdgasdg'];
// $json = json_encode($data);
// $value = json_decode('{"payload":{"foo":"bar","baz":3},"signature":"asdgasdg"}', JSON_OBJECT_AS_ARRAY);
// $deviceID = "USR1-PLANA-IMAC";
// $hashedID = hash("sha256", $dev);

	$printedSignature = "N/A";
	$key = "";
	$payload = "";
	if (isset($_POST['key']) && isset($_POST['payload'])) {
		$key = $_POST['key'];
		$payload = $_POST['payload'];
		if (openssl_sign($payload, $signature, $key, OPENSSL_ALGO_SHA256)) {
			$printedSignature = base64_encode($signature);
		}
	}
?>

<html>
<body>
	<p>Signature is:</p>
	<input type="text" value="<?=$printedSignature?>" style="width:400px">
	<form action="sign.php" method="post">
		<label>Private Key</label><br/>
		<textarea name="key" rows="20" cols="50">
<?php if (isset($_POST['key'])) {?>
<?=$_POST['key']?>
<?php } ?>
</textarea><br/>
		<label>Payload</label><br/>
		<input type="json" name="payload" style="width: 400px", value="<?=htmlspecialchars($payload)?>"><br/>
		<input type="submit">
	</form>
</body>
</html>