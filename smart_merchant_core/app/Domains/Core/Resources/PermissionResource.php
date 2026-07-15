<?php

namespace App\Domains\Core\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PermissionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        // Parse the hierarchical permission name: module.group.action (e.g. core.branch.view)
        $parts = explode('.', $this->name);
        
        $module = $parts[0] ?? null;
        $group  = $parts[1] ?? null;
        $action = $parts[2] ?? null;

        return [
            'id'          => $this->id,
            'name'        => $this->name,
            'group_name'  => $this->group_name,
            'description' => $this->description,
            'parsed_data' => [
                'module' => $module,
                'group'  => $group,
                'action' => $action,
            ],
            'created_at'  => $this->created_at,
            'updated_at'  => $this->updated_at,
        ];
    }
}
