@extends('errors.layout')

@section('title', 'Server Error')
@section('status', '500')
@section('tone', 'tone-danger')
@section('heading', 'Something Went Wrong')
@section('message', 'An unexpected error occurred on our end. The issue has been logged and we are working on it — please try again in a moment.')

@section('icon')
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="8" rx="2"/><rect x="2" y="13" width="20" height="8" rx="2"/><path stroke-linecap="round" stroke-linejoin="round" d="M6 7h.01M6 17h.01"/></svg>
@endsection