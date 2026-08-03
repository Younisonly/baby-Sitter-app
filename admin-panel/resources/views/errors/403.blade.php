@extends('errors.layout')

@section('title', 'Forbidden')
@section('status', '403')
@section('heading', 'Access Denied')
@section('message', 'You do not have permission to access this page. If you believe this is a mistake, please contact your administrator.')

@section('icon')
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><rect x="4" y="11" width="16" height="10" rx="2"/><path stroke-linecap="round" stroke-linejoin="round" d="M8 11V7a4 4 0 018 0v4"/></svg>
@endsection