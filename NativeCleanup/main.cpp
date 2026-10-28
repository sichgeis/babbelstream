#include "llama.h"
#include <algorithm>
#include <cstdio>
#include <iostream>
#include <string>
#include <vector>
#include <unistd.h>
#include <fcntl.h>

static void silent_log(ggml_log_level, const char *, void *) {}
static void batch_tokens(llama_batch_ext *batch, const llama_token *tokens, int n, int position) {
    llama_batch_ext_clear(batch);
    for (int i = 0; i < n; ++i) {
        int idx = llama_batch_ext_add_token(batch, 0, tokens[i]);
        llama_pos pos = position + i;
        llama_batch_ext_set_pos(batch, idx, &pos);
    }
    llama_batch_ext_set_output_logits(batch, n - 1, true);
}
int main(int argc, char **argv) {
    // Libraries cannot write console content. Only the completed result uses the
    // duplicated private result pipe; no partial draft escapes on failure.
    int result_fd = dup(STDOUT_FILENO);
    int null_fd = open("/dev/null", O_WRONLY);
    if (result_fd < 0 || null_fd < 0 || argc != 2) return 1;
    dup2(null_fd, STDOUT_FILENO); dup2(null_fd, STDERR_FILENO); close(null_fd);
    llama_log_set(silent_log, nullptr); ggml_log_set(silent_log, nullptr);
    std::string prompt;
    char buffer[4096];
    while (std::cin.read(buffer, sizeof(buffer)) || std::cin.gcount()) {
        prompt.append(buffer, std::cin.gcount());
        if (prompt.size() > 131072) return 1;
    }
    llama_backend_init();
    auto mp = llama_model_default_params(); mp.n_gpu_layers = 99;
    auto *model = llama_model_load_from_file(argv[1], mp);
    if (!model) return 1;
    if (prompt.empty()) { llama_model_free(model); return 0; }
    auto *vocab = llama_model_get_vocab(model);
    int count = -llama_tokenize(vocab, prompt.data(), prompt.size(), nullptr, 0, true, true);
    const int max_output = 4096;
    if (count <= 0 || count + max_output > 8192) return 1;
    std::vector<llama_token> tokens(count);
    if (llama_tokenize(vocab, prompt.data(), prompt.size(), tokens.data(), count, true, true) < 0) return 1;
    auto cp = llama_context_default_params(); cp.n_ctx = 8192; cp.n_batch = 512; cp.n_ubatch = 512;
    cp.no_perf = true;
    auto *ctx = llama_init_from_model(model, cp);
    if (!ctx) return 1;
    auto *batch = llama_batch_ext_init(ctx);
    for (int start = 0; start < count; start += 512) {
        int n = std::min(512, count - start);
        batch_tokens(batch, tokens.data() + start, n, start);
        if (llama_process(ctx, LLAMA_PROCESS_TYPE_DECODE, batch)) return 1;
    }
    auto *sampler = llama_sampler_init_greedy();
    std::string result; bool complete = false;
    for (int i = 0; i < max_output; ++i) {
        auto token = llama_sampler_sample(sampler, ctx, -1);
        if (llama_vocab_is_eog(vocab, token)) { complete = true; break; }
        char piece[512]; int n = llama_token_to_piece(vocab, token, piece, sizeof(piece), 0, true);
        if (n < 0) return 1;
        result.append(piece, n);
        batch_tokens(batch, &token, 1, count + i);
        if (llama_process(ctx, LLAMA_PROCESS_TYPE_DECODE, batch)) return 1;
    }
    llama_batch_ext_free(batch); llama_sampler_free(sampler); llama_free(ctx); llama_model_free(model);
    if (!complete || result.empty()) return 1;
    size_t written = 0;
    while (written < result.size()) {
        auto n = write(result_fd, result.data() + written, result.size() - written);
        if (n <= 0) return 1;
        written += n;
    }
    close(result_fd); return 0;
}
