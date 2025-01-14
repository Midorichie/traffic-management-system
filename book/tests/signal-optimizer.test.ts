import { describe, it, expect } from 'vitest';
import { deployContract, callPublicFunction } from 'clarity-tools';

describe('Signal Optimizer Contract', () => {
  const contractName = 'signal-optimizer';

  it('should deploy successfully', async () => {
    const result = await deployContract(contractName);
    expect(result.success).toBe(true);
  });

  it('should optimize signal timings', async () => {
    const result = await callPublicFunction(contractName, 'optimize-signals', [5]);
    expect(result.success).toBe(true);
  });

  it('should calculate optimized pattern', async () => {
    const result = await callPublicFunction(contractName, 'calculate-pattern', ['ST1ABCDEFG0000000000000000000000000']);
    expect(result.success).toBe(true);
  });
});
