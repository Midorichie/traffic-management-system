import { describe, it, expect } from 'vitest';
import { deployContract, callPublicFunction } from 'clarity-tools';

describe('Traffic Data Contract', () => {
  const contractName = 'traffic-data';

  it('should deploy successfully', async () => {
    const result = await deployContract(contractName);
    expect(result.success).toBe(true);
  });

  it('should register an intersection', async () => {
    const intersection = 'ST1ABCDEFG0000000000000000000000000';
    const result = await callPublicFunction(contractName, 'register-intersection', [intersection]);
    expect(result.success).toBe(true);
    expect(result.value).toBe('ok');
  });

  it('should submit sensor data', async () => {
    const result = await callPublicFunction(contractName, 'submit-sensor-data', [1, 50, 60, 'ST1ABCDEFG0000000000000000000000000']);
    expect(result.success).toBe(true);
  });

  it('should retrieve traffic patterns', async () => {
    const result = await callPublicFunction(contractName, 'get-traffic-pattern', ['ST1ABCDEFG0000000000000000000000000', 5]);
    expect(result.success).toBe(true);
  });
});
