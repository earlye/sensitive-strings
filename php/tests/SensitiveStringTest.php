<?php

declare(strict_types=1);

namespace SensitiveString\Tests;

use PHPUnit\Framework\TestCase;
use SensitiveString\SensitiveString;

class SensitiveStringTest extends TestCase
{
    public function testToStringShowsHash(): void
    {
        $secret = new SensitiveString('my-secret');
        $result = (string)$secret;

        $this->assertStringStartsWith('sha256:', $result);
        $this->assertStringNotContainsString('my-secret', $result);
        $this->assertEquals(71, strlen($result)); // "sha256:" (7) + 64 hex chars
    }

    public function testConsistentHash(): void
    {
        $secret1 = new SensitiveString('consistent');
        $secret2 = new SensitiveString('consistent');

        $this->assertEquals((string)$secret1, (string)$secret2);
    }

    public function testGetValueReturnsPlaintext(): void
    {
        $secret = new SensitiveString('my-secret');
        $this->assertEquals('my-secret', $secret->getValue());
    }

    public function testValuePropertyReturnsPlaintext(): void
    {
        $secret = new SensitiveString('my-secret');
        $this->assertEquals('my-secret', $secret->value);
    }

    public function testJsonEncode(): void
    {
        $secret = new SensitiveString('secret123');
        $json = json_encode($secret);

        $this->assertStringContainsString('sha256:', $json);
        $this->assertStringNotContainsString('secret123', $json);
    }

    public function testJsonEncodeInArray(): void
    {
        $data = ['password' => new SensitiveString('secret')];
        $json = json_encode($data);

        $this->assertStringContainsString('sha256:', $json);
        $this->assertStringNotContainsString('secret', $json);
    }

    public function testLength(): void
    {
        $secret = new SensitiveString('12345');
        $this->assertEquals(5, $secret->length());
    }

    public function testIsEmpty(): void
    {
        $empty = new SensitiveString('');
        $notEmpty = new SensitiveString('value');

        $this->assertTrue($empty->isEmpty());
        $this->assertFalse($notEmpty->isEmpty());
    }

    public function testIsSensitiveString(): void
    {
        $secret = new SensitiveString('test');

        $this->assertTrue(SensitiveString::isSensitiveString($secret));
        $this->assertFalse(SensitiveString::isSensitiveString('plain'));
        $this->assertFalse(SensitiveString::isSensitiveString(null));
    }

    public function testExtractValue(): void
    {
        $secret = new SensitiveString('secret');

        $this->assertEquals('secret', SensitiveString::extractValue($secret));
        $this->assertEquals('plain', SensitiveString::extractValue('plain'));
        $this->assertNull(SensitiveString::extractValue(null));
    }

    public function testExtractRequiredValue(): void
    {
        $secret = new SensitiveString('secret');

        $this->assertEquals('secret', SensitiveString::extractRequiredValue($secret));
        $this->assertEquals('plain', SensitiveString::extractRequiredValue('plain'));

        $this->expectException(\InvalidArgumentException::class);
        SensitiveString::extractRequiredValue(null);
    }

    public function testSensitive(): void
    {
        $secret = new SensitiveString('original');

        // Already sensitive - returns same object
        $result = SensitiveString::sensitive($secret);
        $this->assertSame($secret, $result);

        // Convert string
        $result = SensitiveString::sensitive('plain');
        $this->assertInstanceOf(SensitiveString::class, $result);
        $this->assertEquals('plain', $result->getValue());

        // null stays null
        $this->assertNull(SensitiveString::sensitive(null));

        // Other types get stringified
        $result = SensitiveString::sensitive(123);
        $this->assertEquals('123', $result->getValue());
    }

    public function testStringInterpolation(): void
    {
        $secret = new SensitiveString('my-secret');
        $message = "Password: $secret";

        $this->assertStringContainsString('sha256:', $message);
        $this->assertStringNotContainsString('my-secret', $message);
    }

    public function testEcho(): void
    {
        $secret = new SensitiveString('my-secret');

        ob_start();
        echo $secret;
        $output = ob_get_clean();

        $this->assertStringStartsWith('sha256:', $output);
        $this->assertStringNotContainsString('my-secret', $output);
    }
}

