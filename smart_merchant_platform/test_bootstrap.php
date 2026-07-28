<?php
$token = '5|hSbYP7Fufn8YyGQdZuUiYBSqbOtxh4B9GfcdY8sn32831563'; // from previous run
$url = 'http://127.0.0.1:8000/api/session/bootstrap';
$options = [
    'http' => [
        'header'  => "Authorization: Bearer $token\r\nAccept: application/json\r\n",
        'method'  => 'GET',
        'ignore_errors' => true,
    ]
];
$context  = stream_context_create($options);
$result = file_get_contents($url, false, $context);
var_dump($http_response_header);
echo "\nBODY:\n";
echo $result;
