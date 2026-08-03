@extends('errors.layout')

@section('title', 'Session Expired')
@section('status', '419')
@section('heading', 'Session Expired')
@section('message', 'Your session has expired due to inactivity. Please sign in again to continue where you left off.')

@section('icon')
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><circle cx="12" cy="13" r="8"/><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v4l2.5 2.5M9 2h6"/></svg>
@endsection