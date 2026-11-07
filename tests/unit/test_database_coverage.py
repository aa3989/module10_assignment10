
"""Unit tests for database session and initialization helpers."""

from unittest.mock import MagicMock, patch

from app import database
from app import database_init


def test_get_db_yields_and_closes_session():
    """Verify get_db provides a session and closes it afterward."""

    mock_session = MagicMock()

    with patch.object(
        database,
        "SessionLocal",
        return_value=mock_session
    ):
        db_generator = database.get_db()

        # Get the database session
        session = next(db_generator)

        assert session is mock_session

        # Complete the generator to trigger cleanup
        try:
            next(db_generator)
        except StopIteration:
            pass
        else:
            raise AssertionError("Expected generator to finish")

        mock_session.close.assert_called_once()


def test_init_db_creates_tables():
    """Verify init_db calls SQLAlchemy's create_all."""

    with patch.object(
        database_init.Base.metadata,
        "create_all"
    ) as mock_create_all:

        database_init.init_db()

        mock_create_all.assert_called_once_with(
            bind=database_init.engine
        )


def test_drop_db_removes_tables():
    """Verify drop_db calls SQLAlchemy's drop_all."""

    with patch.object(
        database_init.Base.metadata,
        "drop_all"
    ) as mock_drop_all:

        database_init.drop_db()

        mock_drop_all.assert_called_once_with(
            bind=database_init.engine
        )
