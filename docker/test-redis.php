<?php
echo "Testing Redis connection...\n";
try {
    $redis = new Redis();
    $connected = $redis->connect(
        getenv('REDIS_HOST'), 
        getenv('REDIS_PORT')
    );
    if (getenv('REDIS_PASSWORD')) {
        $redis->auth(getenv('REDIS_PASSWORD'));
    }
    echo "Redis connected successfully!\n";
    echo "Ping: " . $redis->ping() . "\n";
} catch (Exception $e) {
    echo "Redis connection failed: " . $e->getMessage() . "\n";
}
?>
