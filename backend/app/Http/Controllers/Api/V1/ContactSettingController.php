<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ContactSettingResource;
use App\Models\ContactSetting;

class ContactSettingController extends Controller
{
    public function index(): ContactSettingResource
    {
        $settings = ContactSetting::firstOrCreate([]);
        return new ContactSettingResource($settings);
    }
}
