require 'pwm'
require 'ble'
require 'ble-uart'

class Motor
  def initialize(positive_pin:, negative_pin:)
    @output_positive = PWM.new(positive_pin, frequency: 100000, duty: 0)
    @output_negative = PWM.new(negative_pin, frequency: 100000, duty: 0)
  end

  def update_duty(duty)
    if duty >= 0
      @output_positive.duty(duty > 100 ? 100 : duty)
      @output_negative.duty(0)
    else
      @output_positive.duty(0)
      @output_negative.duty(-duty > 100 ? 100 : -duty)
    end
  end
end

class Car
  RIGHT_POSITIVE_PIN = 5
  RIGHT_NEGATIVE_PIN = 6
  LEFT_POSITIVE_PIN = 7
  LEFT_NEGATIVE_PIN = 8

  def initialize
    @right_motor = Motor.new(positive_pin: RIGHT_POSITIVE_PIN, negative_pin: RIGHT_NEGATIVE_PIN)
    @left_motor = Motor.new(positive_pin: LEFT_POSITIVE_PIN, negative_pin: LEFT_NEGATIVE_PIN)
  end

  def update(x, y)
    if y.abs < 5
      @right_motor.update_duty(0)
      @left_motor.update_duty(0)
      puts "x:#{x} y:#{y} -> STOP"
      return
    end

    variable = y / 100.0 * 40
    turn = x / 100.0 * 40

    if y > 0
      right_duty = variable + 60 + turn
      left_duty = variable + 60 - turn
    else
      right_duty = variable - 60 - turn
      left_duty = variable - 60 + turn
    end

    @right_motor.update_duty(right_duty.to_i)
    @left_motor.update_duty(left_duty.to_i)
    puts "x:#{x} y:#{y} -> R:#{right_duty.to_i} L:#{left_duty.to_i}"
  end
end

TIMEOUT_LOOPS = 50

car = Car.new
uart = BLE::UART.new(name: "RCCar")
timeout_counter = 0

uart.start do
  if uart.available?
    data = uart.read_nonblock(256)
    if data && data.bytesize >= 2
      # 末尾2バイトを取得（最新のコマンドのみ使用）
      raw_x = data.getbyte(data.bytesize - 2)
      raw_y = data.getbyte(data.bytesize - 1)
      # unsigned → signed int8 変換
      x = raw_x > 127 ? raw_x - 256 : raw_x
      y = raw_y > 127 ? raw_y - 256 : raw_y
      car.update(x, y)
      timeout_counter = 0
    end
  else
    timeout_counter += 1
    if timeout_counter > TIMEOUT_LOOPS
      puts "TIMEOUT: no command received"
      car.update(0, 0)
      timeout_counter = 0
    end
  end
end
