from app.utils.media_urls import normalize_institution_logo_url


def test_normalize_relative_logo_path_unchanged():
    path = "/api/v1/media/logos/institution_1_abcd12345678.png"
    assert normalize_institution_logo_url(path) == path


def test_normalize_localhost_full_url_to_relative():
    url = "http://localhost:8000/api/v1/media/logos/institution_2_abcd12345678.jpg"
    assert (
        normalize_institution_logo_url(url)
        == "/api/v1/media/logos/institution_2_abcd12345678.jpg"
    )


def test_normalize_external_url_unchanged():
    url = "https://cdn.example.com/assets/logo.png"
    assert normalize_institution_logo_url(url) == url


def test_normalize_empty_values():
    assert normalize_institution_logo_url(None) is None
    assert normalize_institution_logo_url("") is None
    assert normalize_institution_logo_url("   ") is None
