<?php

namespace Tests;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Facades\Facade;
use Illuminate\Support\Facades\ParallelTesting;
use RuntimeException;

abstract class TestCase extends BaseTestCase
{
    /**
     * Known development database name that must never be targeted by tests.
     */
    public const DEVELOPMENT_DATABASE_NAME = 'smart_merchant_platform';

    /**
     * Setup the test environment.
     * Intercepts test environment lifecycle to enforce database isolation
     * BEFORE any trait (including RefreshDatabase) runs.
     */
    protected function setUpTheTestEnvironment(): void
    {
        Facade::clearResolvedInstances();

        if (! $this->app) {
            $this->refreshApplication();

            ParallelTesting::callSetUpTestCaseCallbacks($this);
        }

        // Enforce database guard immediately after app boots, prior to trait execution
        $this->guardAgainstNonTestDatabase();

        $this->setUpTraits();

        foreach ($this->afterApplicationCreatedCallbacks as $callback) {
            $callback();
        }

        Model::setEventDispatcher($this->app['events']);

        $this->setUpHasRun = true;
    }

    /**
     * Strictly verifies that the current runtime environment and database connection
     * point to an isolated test database and not to development or production.
     *
     * @throws RuntimeException
     */
    protected function guardAgainstNonTestDatabase(): void
    {
        $connection = config('database.default', 'pgsql');
        $database = (string) config("database.connections.{$connection}.database");
        $host = (string) config("database.connections.{$connection}.host");
        $url = (string) config("database.connections.{$connection}.url");
        $environment = app()->environment();

        self::validateDatabaseSafety($connection, $database, $environment, $host, $url);
    }

    /**
     * Pure validation logic to ensure test safety against destructive operations.
     *
     * @throws RuntimeException
     */
    public static function validateDatabaseSafety(
        string $connection,
        ?string $database,
        string $environment,
        ?string $host = null,
        ?string $url = null
    ): void {
        // 1. Environment Guard
        if ($environment !== 'testing') {
            throw new RuntimeException("REFUSING TO RUN TESTS AGAINST NON-TEST DATABASE: Environment is '{$environment}', expected 'testing'.");
        }

        // 2. Database Name Required
        if (empty($database)) {
            throw new RuntimeException("REFUSING TO RUN TESTS AGAINST NON-TEST DATABASE: Database name cannot be empty.");
        }

        $lowerDb = strtolower($database);

        // 3. Production Guard
        if (
            $environment === 'production' ||
            str_contains($lowerDb, 'production') ||
            str_contains($lowerDb, 'prod') ||
            ($host !== null && str_contains(strtolower($host), 'prod')) ||
            ($url !== null && str_contains(strtolower($url), 'prod'))
        ) {
            throw new RuntimeException("REFUSING TO RUN TESTS AGAINST NON-TEST DATABASE: Production database detected [{$database}].");
        }

        // 4. Development Database Guard
        if ($database === self::DEVELOPMENT_DATABASE_NAME) {
            throw new RuntimeException("REFUSING TO RUN TESTS AGAINST NON-TEST DATABASE: Connected to active development database [" . self::DEVELOPMENT_DATABASE_NAME . "].");
        }

        // 5. Testing Marker Guard
        $isMemorySqlite = ($connection === 'sqlite' && ($database === ':memory:' || str_contains($lowerDb, 'test')));
        $hasTestingMarker = str_contains($lowerDb, 'test') || str_contains($lowerDb, 'testing');

        if (!$isMemorySqlite && !$hasTestingMarker) {
            throw new RuntimeException("REFUSING TO RUN TESTS AGAINST NON-TEST DATABASE: Database [{$database}] does not contain an approved testing marker.");
        }
    }
}
