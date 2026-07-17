<?php

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Domains\Catalog\Resources\CategoryResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use App\Domains\Catalog\Models\Category;

// Requests
use App\Domains\Catalog\Requests\StoreCategoryRequest;
use App\Domains\Catalog\Requests\ViewCategoryRequest;
use App\Domains\Catalog\Requests\ListCategoriesRequest;
use App\Domains\Catalog\Requests\SearchCategoriesRequest;
use App\Domains\Catalog\Requests\UpdateCategoryRequest;
use App\Domains\Catalog\Requests\DeleteCategoryRequest;
use App\Domains\Catalog\Requests\ActivateCategoryRequest;
use App\Domains\Catalog\Requests\DeactivateCategoryRequest;

// DTOs
use App\Domains\Catalog\DTOs\CreateCategoryDTO;
use App\Domains\Catalog\DTOs\ViewCategoryDTO;
use App\Domains\Catalog\DTOs\CategoryListCriteriaDTO;
use App\Domains\Catalog\DTOs\CategoriesearchCriteriaDTO;
use App\Domains\Catalog\DTOs\UpdateCategoryDTO;

// Actions
use App\Domains\Catalog\Actions\Category\CreateCategoryAction;
use App\Domains\Catalog\Actions\Category\ViewCategoryAction;
use App\Domains\Catalog\Actions\Category\ListCategoriesAction;
use App\Domains\Catalog\Actions\Category\SearchCategoriesAction;
use App\Domains\Catalog\Actions\Category\UpdateCategoryAction;
use App\Domains\Catalog\Actions\Category\DeleteCategoryAction;
use App\Domains\Catalog\Actions\Category\ActivateCategoryAction;
use App\Domains\Catalog\Actions\Category\DeactivateCategoryAction;

class CategoryController extends Controller
{
    use AuthorizesRequests;

    public function index(ListCategoriesRequest $request, ListCategoriesAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Category::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = CategoryListCriteriaDTO::fromRequest($data);
        return CategoryResource::collection($action->handle($criteria));
    }

    public function search(SearchCategoriesRequest $request, SearchCategoriesAction $action): AnonymousResourceCollection
    {
        $this->authorize('viewAny', Category::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $criteria = CategoriesearchCriteriaDTO::fromRequest($data);
        return CategoryResource::collection($action->handle($criteria));
    }

    public function show(string $id, ViewCategoryRequest $request, ViewCategoryAction $action): JsonResponse
    {
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = ViewCategoryDTO::fromRequest($data, $id);
        $category = $action->handle($dto);
        $this->authorize('view', $category);
        return response()->json(new CategoryResource($category));
    }

    public function store(StoreCategoryRequest $request, CreateCategoryAction $action): JsonResponse
    {
        $this->authorize('create', Category::class);
        $data = $request->validated();
        $data['business_id'] = $request->user()->business_id;
        $dto = CreateCategoryDTO::fromRequest($data);
        $category = $action->handle($dto);
        return response()->json(new CategoryResource($category), 201);
    }

    public function update(string $id, UpdateCategoryRequest $request, UpdateCategoryAction $action, ViewCategoryAction $viewAction): JsonResponse
    {
        $viewDto = ViewCategoryDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $category = $viewAction->handle($viewDto);
        $this->authorize('update', $category);

        $dto = UpdateCategoryDTO::fromRequest($request->validated());
        $updatedCategory = $action->handle($category, $dto);
        return response()->json(new CategoryResource($updatedCategory));
    }

    public function destroy(string $id, DeleteCategoryRequest $request, DeleteCategoryAction $action, ViewCategoryAction $viewAction): JsonResponse
    {
        $viewDto = ViewCategoryDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $category = $viewAction->handle($viewDto);
        $this->authorize('delete', $category);

        $action->handle($category);
        return response()->json(null, 204);
    }

    public function activate(string $id, ActivateCategoryRequest $request, ActivateCategoryAction $action, ViewCategoryAction $viewAction): JsonResponse
    {
        $viewDto = ViewCategoryDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $category = $viewAction->handle($viewDto);
        $this->authorize('update', $category);

        $activatedCategory = $action->handle($category);
        return response()->json(new CategoryResource($activatedCategory));
    }

    public function deactivate(string $id, DeactivateCategoryRequest $request, DeactivateCategoryAction $action, ViewCategoryAction $viewAction): JsonResponse
    {
        $viewDto = ViewCategoryDTO::fromRequest(['business_id' => $request->user()->business_id], $id);
        $category = $viewAction->handle($viewDto);
        $this->authorize('update', $category);

        $deactivatedCategory = $action->handle($category);
        return response()->json(new CategoryResource($deactivatedCategory));
    }
}






