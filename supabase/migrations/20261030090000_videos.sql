-- 동영상도 올리기 (무료 요금제 파일당 한도 50MB에 맞춤). 사진은 화면에서 줄여서 올림
update storage.buckets
set file_size_limit = 52428800,
    allowed_mime_types = array['image/jpeg', 'video/mp4', 'video/quicktime', 'video/webm']
where id = 'photos';
