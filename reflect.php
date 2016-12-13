<?php
$path = $argv[1];
$class = $argv[2];
require($path);
$reflector = new ReflectionClass($class);
echo $reflector->getFileName();

