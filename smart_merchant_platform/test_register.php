<?php
$url = 'http://127.0.0.1:8000/api/auth/register';
$data = ['first_name' => 'Bashir', 'last_name' => 'Alazaki', 'email' => 'bashir_'.time().'@example.com', 'phone' => '1234'.rand(1000,9999), 'password' => 'admin123', 'username' => 'bashir_'.time()];
$options = [
    'http' => [
        'header'  => "Content-type: application/json\r\nAccept: application/json\r\n",
        'method'  => 'POST',
        'content' => json_encode($data),
        'ignore_errors' => true,
    ]
];
$context  = stream_context_create($options);
$result = file_get_contents($url, false, $context);
var_dump($http_response_header);
echo "\nBODY:\n";
echo $result;
