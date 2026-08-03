@extends('errors.layout')

@section('title', 'Page Not Found')
@section('status', '404')
@section('heading', 'Page Not Found')
@section('message', 'The page you are looking for might have been removed, renamed, or never existed. Let us get you back on track.')

@section('icon')
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-4.35-4.35M11 8v4l2.5 2.5"/></svg>
@endsection