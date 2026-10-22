<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    protected $authService;

    public function __construct(AuthService $authService)
    {
        $this->authService = $authService;
    }

    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required_without:phone|string',
            'phone' => 'nullable|string',
            'password' => 'required',
        ]);

        $loginIdentifier = $request->input('email') ?: $request->input('phone');

        $result = $this->authService->login(
            $loginIdentifier,
            $request->input('password'),
            $request->input('device_name')
        );

        return response()->json([
            'message' => 'Login successful',
            'token' => $result['token'],
            'user' => new UserResource($result['user']),
        ]);
    }

    public function register(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'nullable|string|max:255',
            'first_name' => 'nullable|string|max:255',
            'last_name' => 'nullable|string|max:255',
            'phone' => 'required|string|max:30',
            'password' => 'required|string|min:6',
            'username' => 'nullable|string|max:255',
            'email' => 'nullable|string|max:255',
            'business_name' => 'nullable|string|max:255',
        ]);

        $result = $this->authService->register(
            $request->all(),
            $request->input('device_name')
        );

        return response()->json([
            'message' => 'Registration successful',
            'token' => $result['token'],
            'user' => new UserResource($result['user']),
        ], 201);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'user' => new UserResource($request->user()),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user());

        return response()->json([
            'message' => 'Logged out successfully.',
        ]);
    }
}
