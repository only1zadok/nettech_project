<?php
$student = getenv('NETTECH_STUDENT') ?: 's1234567';
echo "<h1>Net-Tech prototype web server</h1>";
echo "<p>Student ID: <strong>{$student}</strong></p>";
echo "<p>Server time: " . date('c') . "</p>";
?>
