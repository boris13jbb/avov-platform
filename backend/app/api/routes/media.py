from fastapi import APIRouter, HTTPException
from fastapi.responses import Response

from app.utils.file_storage import read_logo_file

router = APIRouter(prefix="/media", tags=["Medios"])


@router.get("/logos/{filename}")
def get_institution_logo(filename: str):
    try:
        content, media_type = read_logo_file(filename)
    except ValueError:
        raise HTTPException(status_code=400, detail="Nombre de archivo inválido") from None
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Logo no encontrado") from None

    return Response(content=content, media_type=media_type)
