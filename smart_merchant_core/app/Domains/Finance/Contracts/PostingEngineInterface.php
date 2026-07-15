<?php

namespace App\Domains\Finance\Contracts;

use App\Domains\Finance\DTOs\PostingEngine\PostingRequestDTO;
use App\Domains\Finance\DTOs\PostingEngine\PostingResultDTO;
use App\Domains\Finance\DTOs\PostingEngine\ReverseRequestDTO;

interface PostingEngineInterface
{
    public function post(PostingRequestDTO $request): PostingResultDTO;
    
    public function reverse(ReverseRequestDTO $request): PostingResultDTO;
}
