@extends('errors.layout')

@section('title', 'Too Many Requests')
@section('status', '429')
@section('tone', 'tone-warning')
@section('heading', 'A Bit Too Quick')
@section('message', 'You have made too many requests in a short time. Please wait a moment and try again.')

@section('icon')
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 15v-2.5a2.5 2.5 0 10-2.5-2.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/><path stroke-linecap="round" stroke-linejoin="round" d="M12 19v-1"/></svg>
@endsection