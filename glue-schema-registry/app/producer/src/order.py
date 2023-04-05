import datetime
import string
import json
import typing
import dataclasses
import enum

from faker import Faker
from dataclasses_avroschema import AvroModel


class Compatibility(enum.Enum):
    NONE = "NONE"
    DISABLED = "DISABLED"
    BACKWARD = "BACKWARD"
    BACKWARD_ALL = "BACKWARD_ALL"
    FORWARD = "FORWARD"
    FORWARD_ALL = "FORWARD_ALL"
    FULL = "FULL"
    FULL_ALL = "FULL_ALL"


class InjectCompatMixin:
    @classmethod
    def updated_avro_schema_to_python(cls, compat: Compatibility = Compatibility.BACKWARD):
        schema = cls.avro_schema_to_python()
        schema["compatibility"] = compat.value
        return schema

    @classmethod
    def updated_avro_schema(cls, compat: Compatibility = Compatibility.BACKWARD):
        schema = cls.updated_avro_schema_to_python(compat)
        return json.dumps(schema)


@dataclasses.dataclass
class OrderItem(AvroModel):
    product_id: int
    quantity: int


@dataclasses.dataclass
class Order(AvroModel, InjectCompatMixin):
    "Online fake order item"
    order_id: str
    ordered_at: datetime.datetime
    user_id: str
    order_items: typing.List[OrderItem]

    class Meta:
        namespace = "Order V1"

    def asdict(self):
        return dataclasses.asdict(self)

    @classmethod
    def auto(cls, fake: Faker = Faker()):
        rand_int = fake.random_int(1, 1000)
        user_id = "".join(
            [string.ascii_lowercase[int(s)] if s.isdigit() else s for s in hex(rand_int)]
        )[::-1]
        order_items = [
            OrderItem(fake.random_int(1, 9999), fake.random_int(1, 10))
            for _ in range(fake.random_int(1, 4))
        ]
        return cls(fake.uuid4(), datetime.datetime.utcnow(), user_id, order_items)

    def create(self, num: int):
        return [self.auto() for _ in range(num)]


@dataclasses.dataclass
class OrderMore(Order):
    is_prime: bool

    @classmethod
    def auto(cls, fake: Faker = Faker()):
        o = Order.auto()
        return cls(o.order_id, o.ordered_at, o.user_id, o.order_items, fake.pybool())
