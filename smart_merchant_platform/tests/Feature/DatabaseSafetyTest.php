<?php

namespace Tests\Feature;

use RuntimeException;
use Tests\TestCase;

class DatabaseSafetyTest extends TestCase
{
    /**
     * Proves that valid testing databases pass validation.
     */
    public function test_testing_database_is_allowed(): void
    {
        // 1. PostgreSQL testing database
        TestCase::validateDatabaseSafety(
            connection: 'pgsql',
            database: 'smart_merchant_platform_testing',
            environment: 'testing'
        );

        // 2. SQLite in-memory testing database
        TestCase::validateDatabaseSafety(
            connection: 'sqlite',
            database: ':memory:',
            environment: 'testing'
        );

        // 3. SQLite test file database
        TestCase::validateDatabaseSafety(
            connection: 'sqlite',
            database: 'testing_database.sqlite',
            environment: 'testing'
        );

        $this->assertTrue(true);
    }

    /**
     * Proves that the live development database is strictly rejected.
     */
    public function test_development_database_is_rejected(): void
    {
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('REFUSING TO RUN TESTS AGAINST NON-TEST DATABASE: Connected to active development database [smart_merchant_platform].');

        TestCase::validateDatabaseSafety(
            connection: 'pgsql',
            database: 'smart_merchant_platform',
            environment: 'testing'
        );
    }

    /**
     * Proves that production environments and production databases are strictly rejected.
     */
    public function test_production_database_is_rejected(): void
    {
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('REFUSING TO RUN TESTS AGAINST NON-TEST DATABASE: Environment is \'production\', expected \'testing\'.');

        TestCase::validateDatabaseSafety(
            connection: 'pgsql',
            database: 'smart_merchant_platform_testing',
            environment: 'production'
        );
    }

    /**
     * Proves that a database name containing production markers is rejected even if APP_ENV=testing.
     */
    public function test_production_named_database_is_rejected(): void
    {
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Production database detected');

        TestCase::validateDatabaseSafety(
            connection: 'pgsql',
            database: 'smart_merchant_platform_prod',
            environment: 'testing'
        );
    }

    /**
     * Proves that database names without an approved testing marker are rejected.
     */
    public function test_missing_testing_marker_is_rejected(): void
    {
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('does not contain an approved testing marker');

        TestCase::validateDatabaseSafety(
            connection: 'pgsql',
            database: 'smart_merchant_analytics',
            environment: 'testing'
        );
    }

    /**
     * Proves that an empty database name is rejected.
     */
    public function test_empty_database_name_is_rejected(): void
    {
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Database name cannot be empty');

        TestCase::validateDatabaseSafety(
            connection: 'pgsql',
            database: '',
            environment: 'testing'
        );
    }

    /**
     * Verifies that the currently running test suite is isolated to smart_merchant_platform_testing.
     */
    public function test_current_runtime_is_connected_to_isolated_testing_database(): void
    {
        $activeDb = config('database.connections.' . config('database.default') . '.database');
        $this->assertEquals('smart_merchant_platform_testing', $activeDb);
        $this->assertEquals('testing', app()->environment());
    }
}
