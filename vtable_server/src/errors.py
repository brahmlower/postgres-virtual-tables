
class ServiceException(Exception):
    def __init__(self, message, status=400):
        super().__init__()
        self.message = message
        self.status_code = status

    def __repr__(self):
        return "{}: {}".format(self.__class__.__name__, self.message)

    def as_dict(self):
        return {
            'error': self.__class__.__name__,
            'message': self.message
        }

# Generic errors

class DatabaseError(ServiceException):
    def __init__(self, error):
        super().__init__('Database error: {}'.format(str(error)), status=500)

class ItemNotFound(ServiceException):
    def __init__(self, item_id):
        super().__init__('Could not find item with id {}'.format(item_id))

class MissingRequiredKey(ServiceException):
    def __init__(self, key, type_='string'):
        super().__init__('Missing required key: {} (of type {})'.format(key, type_))

class NotImplementedYet(ServiceException):
    def __init__(self):
        super().__init__('This feature not implemented yet!', status=500)

class ItemNotFound(ServiceException):
    def __init__(self, item_id):
        super().__init__('No item with id: {}'.format(item_id))
