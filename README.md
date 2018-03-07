Estimater
================================
Estimater is a hardware evaluation script for deep learning models. It uses formulas and hardware configurations to calculate useful values such as data size, performance, memory access...,etc. We can use Estimater to evaluate if it is suitable that running target model on selected hardware.

- Steps to run Estimater
1. Transfer model description(Caffee, TensorFlow...etc) to representation of NNVM(.json).
2. Set hardware configure(hw_config.pl).
3. Input the representation and execute with Performance estimation tool(Estimater.pl).

> perl /path/to/Performance_Estimater.pl -f /path/to/model.json -o /path/to/Result.csv

Verification
--------------------------------
Benchmark Generator script can be used to generate configurations setting and trigger commands of accelerator for different models layer by layer. We can use generated instructions to run an actual accelerator with simulation.

- Steps to run Benchmark Generator
1. Transfer model description(Caffee, TensorFlow...etc) to representation of NNVM(.json).
2. Input the representation and execute with Benchmark Generator(Benchmark_Generator.pl).
3. Transfer output(input.txn) to hexdump format(input.txn.raw).
3. Run output(input.txn.raw) on testbench of accelerator with simulation to check performance.

> perl /path/to/Benchmark_Generator.pl -f /path/to/model.json -o /path/to/input.txn

