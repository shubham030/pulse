package client

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type Client struct {
	baseURL string
	http    *http.Client
}

func New(host string, port int) *Client {
	return &Client{
		baseURL: fmt.Sprintf("http://%s:%d", host, port),
		http:    &http.Client{Timeout: 5 * time.Second},
	}
}

type TimerRequest struct {
	Duration int    `json:"duration"`
	Label    string `json:"label"`
	Sound    bool   `json:"sound"`
}

type OkResponse struct {
	OK    bool   `json:"ok"`
	Error string `json:"error,omitempty"`
}

type StatusResponse struct {
	Running   bool   `json:"running"`
	Remaining int    `json:"remaining"`
	Label     string `json:"label"`
}

func (c *Client) Start(req TimerRequest) error {
	body, err := json.Marshal(req)
	if err != nil {
		return err
	}

	resp, err := c.http.Post(c.baseURL+"/timer", "application/json", bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var ok OkResponse
	if err := json.NewDecoder(resp.Body).Decode(&ok); err != nil {
		return fmt.Errorf("decode response: %w", err)
	}

	if !ok.OK {
		return fmt.Errorf("server error: %s", ok.Error)
	}
	return nil
}

func (c *Client) Stop() error {
	resp, err := c.http.Post(c.baseURL+"/stop", "application/json", nil)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var ok OkResponse
	if err := json.NewDecoder(resp.Body).Decode(&ok); err != nil {
		return fmt.Errorf("decode response: %w", err)
	}
	return nil
}

func (c *Client) Status() (*StatusResponse, error) {
	resp, err := c.http.Get(c.baseURL + "/status")
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	var status StatusResponse
	if err := json.NewDecoder(resp.Body).Decode(&status); err != nil {
		return nil, fmt.Errorf("decode response: %w", err)
	}
	return &status, nil
}
